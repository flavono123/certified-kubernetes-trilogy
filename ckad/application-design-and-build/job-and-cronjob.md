# Job and CronJob

## Job
*Job*은 일시적으로 실행되는 작업을 실행하는 워크로드 자원입니다. *Job*은 성공적으로 완료될 때까지 실행을 유지하며, 각 작업의 복제본을 병렬로 실행할 수 있습니다. *Job*은 일괄 처리 작업에 적합하며, 성공적으로 완료되면 종료됩니다. 이러한 작업은 배치 프로세스 및 데이터 처리에 유용합니다.

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: pi
spec:
  parallelism: 3
  template:
    spec:
      containers:
      - name: pi
        image: perl:5.34.0
        command: ["perl",  "-Mbignum=bpi", "-wle", "print bpi(2000)"]
      restartPolicy: Never
  backoffLimit: 4
```

위 *Job*은, 시간이 수 초 걸리는 배치 작업의 간단한 예시로, 2000자리의 파이 값을 계산합니다.

스펙은 다른 `apps` 그룹의 워크로드 자원과 비슷하게, `spec.template`에서 *Pod*의 스펙을 포함하고 있습니다.

*Job*은 `backoffLimit`를 사용하여 재시도 횟수를 지정할 수 있습니다. 이 경우, 재시도 횟수가 4회이므로, *Job*은 최대 5번 실행됩니다. *Job*이 성공적으로 완료되면, *Job*은 완료된 상태로 종료됩니다.

```sh
$ k get po -l job-name=pi -w
pi-jmc6g    0/1     ContainerCreating   0               13s
pi-jmc6g    1/1     Running             0               26s
pi-jmc6g    0/1     Completed           0               33s
pi-jmc6g    0/1     Completed           0               34s
pi-jmc6g    0/1     Completed           0               35s
pi-jmc6g    0/1     Completed           0               35s
```

*Job*이 실행하는 Pod엔 `job-name=<job>` 레이블이 붙습니다.

```sh
$ k logs pi-jmc6g
3.1415926535897932384626433832795028841971693993751058209749445923078164062862089986280348253421170679821480865132823066470938446095505822317253594081284811174502841027019385211055596446229489549303819644288109756659334461284756482337867831652712019091456485669234603486104543266482133936072602491412737245870066063155881748815209209628292540917153643678925903600113305305488204665213841469519415116094330572703657595919530921861173819326117931051185480744623799627495673518857527248912279381830119491298336733624406566430860213949463952247371907021798609437027705392171762931767523846748184676694051320005681271452635608277857713427577896091736371787214684409012249534301465495853710507922796892589235420199561121290219608640344181598136297747713099605187072113499999983729780499510597317328160963185950244594553469083026425223082533446850352619311881710100031378387528865875332083814206171776691473035982534904287554687311595628638823537875937519577818577805321712268066130019278766111959092164201989380952572010654858632788659361533818279682303019520353018529689957736225994138912497217752834791315155748572424541506959508295331168617278558890750983817546374649393192550604009277016711390098488240128583616035637076601047101819429555961989467678374494482553797747268471040475346462080466842590694912933136770289891521047521620569660240580381501935112533824300355876402474964732639141992726042699227967823547816360093417216412199245863150302861829745557067498385054945885869269956909272107975093029553211653449872027559602364806654991198818347977535663698074265425278625518184175746728909777727938000816470600161452491921732172147723501414419735685481613611573525521334757418494684385233239073941433345477624168625189835694855620992192221842725502542568876717904946016534668049886272327917860857843838279679766814541009538837863609506800642251252051173929848960841284886269456042419652850222106611863067442786220391949450471237137869609563643719172874677646575739624138908658326459958133904780275901
```

로그에서 *Job* 출력을 확인할 수 있습니다.

```sh
$ k describe job pi
Name:             pi
Namespace:        default
Selector:         controller-uid=28f1af76-f5cf-4779-b9b2-c23eba87abbe
Labels:           controller-uid=28f1af76-f5cf-4779-b9b2-c23eba87abbe
                  job-name=pi
Annotations:      batch.kubernetes.io/job-tracking:
Parallelism:      1
Completions:      1
Completion Mode:  NonIndexed
Start Time:       Tue, 18 Apr 2023 23:24:34 +0000
Completed At:     Tue, 18 Apr 2023 23:25:09 +0000
Duration:         35s
Pods Statuses:    0 Active (0 Ready) / 1 Succeeded / 0 Failed
Pod Template:
  Labels:  controller-uid=28f1af76-f5cf-4779-b9b2-c23eba87abbe
           job-name=pi
  Containers:
   pi:
    Image:      perl:5.34.0
    Port:       <none>
    Host Port:  <none>
    Command:
      perl
      -Mbignum=bpi
      -wle
      print bpi(2000)
    Environment:  <none>
    Mounts:       <none>
  Volumes:        <none>
Events:
  Type    Reason            Age    From            Message
  ----    ------            ----   ----            -------
  Normal  SuccessfulCreate  6m2s   job-controller  Created pod: pi-jmc6g
  Normal  Completed         5m27s  job-controller  Job completed
```

완료한 *Job*의 상태에서 걸린 시간(Duration)과 시작, 끝 시각(Start Time, Completed At) 그리고 파드의 상태(Pods Statuses)를 확인할 수 있습니다.

## Job 병렬 실행
앞서 살펴 본 예시는 비 병렬(Non-paralell) 실행 *Job*이었습니다. 병렬 실행 *Job*은 `spec.parallelism`를 2 이상으로 설정하면 됩니다(기본 값 1).

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: parallel-pi
spec
  parallelism: 3
  template:
    spec:
      containers:
      - name: pi
        image: perl:5.34.0
        command: ["perl",  "-Mbignum=bpi", "-wle", "print bpi(2000)"]
      restartPolicy: Never
  backoffLimit: 4
```

```sh
$ k describe job parallel-pi
Name:             parallel-pi
Namespace:        default
Selector:         controller-uid=b226b878-be11-4d45-9910-88de0ad858a3
Labels:           controller-uid=b226b878-be11-4d45-9910-88de0ad858a3
                  job-name=parallel-pi
Annotations:      batch.kubernetes.io/job-tracking:
Parallelism:      3
Completions:      <unset>
Completion Mode:  NonIndexed
Start Time:       Wed, 19 Apr 2023 00:34:59 +0000
Completed At:     Wed, 19 Apr 2023 00:35:15 +0000
Duration:         16s
Pods Statuses:    0 Active (0 Ready) / 3 Succeeded / 0 Failed
Pod Template:
  Labels:  controller-uid=b226b878-be11-4d45-9910-88de0ad858a3
           job-name=parallel-pi
  Containers:
   pi:
    Image:      perl:5.34.0
    Port:       <none>
    Host Port:  <none>
    Command:
      perl
      -Mbignum=bpi
      -wle
      print bpi(2000)
    Environment:  <none>
    Mounts:       <none>
  Volumes:        <none>
Events:
  Type    Reason            Age   From            Message
  ----    ------            ----  ----            -------
  Normal  SuccessfulCreate  15s   job-controller  Created pod: parallel-pi-6dwrl
  Normal  SuccessfulCreate  15s   job-controller  Created pod: parallel-pi-bwjjh
  Normal  SuccessfulCreate  15s   job-controller  Created pod: parallel-pi-zvbg9
  Normal  Completed         0s    job-controller  Job completed
```

`spec.parallelism`를 3으로 설정하고 *Job*을 생성하면 3개의 파드가 동시에 생성됩니다. 동시에 실행되는 셋 중 하나라도 성공하면 *Job*은 성공으로 완료됩니다. 하지만 파이를 계산하는 예제는 거의 항상 성공할 것이라 결과는 대부분, 세개의 파드가 동시에 실행되고 모두 성공하는, 아래처럼 나올 것입니다.

```sh
$ k get job parallel-pi
NAME                 COMPLETIONS   DURATION   AGE
parallel-pi          3/1 of 3      16s        23m
```

랜덤하게 실패하는 컨테이너를 사용해서 병렬 실행 *Job*이 실패하는 경우를 만들어 보겠습니다.

```yaml
# manifest를 heredoc으로 적용한다면 명령이 치환되지 않도록 ''로 감싸야 합니다.
# e.g. `$ cat <<'EOF' | k apply -f -`
# https://stackoverflow.com/questions/4937792/using-variables-inside-a-bash-heredoc
apiVersion: batch/v1
kind: Job
metadata:
  name: success-or-failure
spec:
  parallelism: 3
  template:
    spec:
      containers:
      - name: random
        image: alpine:3.14.0
        command:
        - sh
        - -c
        - |
          exit_code=$(( $RANDOM % 4 )) # 0, 1, 2, 3 중 하나의 값을 반환
          if [ $exit_code -eq 0 ]; then
            echo "success"
          else
            echo "failure"
          fi
          sleep $exit_code

          exit $exit_code
      restartPolicy: Never
  backoffLimit: 20
```

25%의 확률로 성공하는 *Job*을 생성했습니다. 성공하는 파드도 있고 실패하는 파드도 있지만 하나라도 성공한다면 *Job*은 완료됩니다. 아래 경우는 동시에 성공한 파드가 2개였습니다.

```sh
$ k get po -l job-name=success-or-failure -w
success-or-failure-fpsm8   1/1     Running     0            2s
success-or-failure-nnkkf   1/1     Running     0            2s
success-or-failure-scps6   1/1     Running     0            2s
success-or-failure-nnkkf   0/1     Completed   0            2s
success-or-failure-scps6   0/1     Completed   0            2s
success-or-failure-fpsm8   0/1     Error       0            3s
success-or-failure-scps6   0/1     Completed   0            4s
success-or-failure-nnkkf   0/1     Completed   0            4s
success-or-failure-fpsm8   0/1     Error       0            4s
success-or-failure-scps6   0/1     Completed   0            4s
success-or-failure-nnkkf   0/1     Completed   0            4s
success-or-failure-nnkkf   0/1     Completed   0            5s
success-or-failure-scps6   0/1     Completed   0            5s
success-or-failure-fpsm8   0/1     Error       0            5s
success-or-failure-fpsm8   0/1     Error       0            6s

$ k describe job success-or-failure
Name:             success-or-failure
Namespace:        default
Selector:         controller-uid=9d95463e-5e20-4bee-bf68-7e95f5f8a5dc
Labels:           controller-uid=9d95463e-5e20-4bee-bf68-7e95f5f8a5dc
                  job-name=success-or-failure
Annotations:      batch.kubernetes.io/job-tracking:
Parallelism:      3
Completions:      <unset>
Completion Mode:  NonIndexed
Start Time:       Wed, 19 Apr 2023 10:36:30 +0000
Completed At:     Wed, 19 Apr 2023 10:36:36 +0000
Duration:         6s
Pods Statuses:    0 Active (0 Ready) / 2 Succeeded / 1 Failed
...
```

`spec.completions`에 *Job*이 성공한 파드의 개수를 설정할 수 있습니다.

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: sof-completions
spec:
  completions: 4
  parallelism: 3
  template:
    spec:
      containers:
      - name: random
        image: alpine:3.14.0
        command:
        - sh
        - -c
        - |
          exit_code=$(( $RANDOM % 4 )) # 0, 1, 2, 3 중 하나의 값을 반환
          if [ $exit_code -eq 0 ]; then
            echo "success"
          else
            echo "failure"
          fi
          sleep $exit_code

          exit $exit_code
      restartPolicy: Never
  backoffLimit: 20
```

```sh
$ k get po -l job-name=sof-completions -w
...

$ k describe job sof-completions
...
Parallelism:      3
Completions:      4
Completion Mode:  NonIndexed
Start Time:       Wed, 19 Apr 2023 10:43:49 +0000
Completed At:     Wed, 19 Apr 2023 10:44:50 +0000
Duration:         61s
Pods Statuses:    0 Active (0 Ready) / 4 Succeeded / 14 Failed
...
```

## 종료된 Job 파드 정리
*Job*으로 실행된 파드는 완료되면 삭제되지 않고 남아 있습니다.

```sh
$ k get po -l job-name=sof-completions
NAME                    READY   STATUS      RESTARTS   AGE
sof-completions-2xwsq   0/1     Completed   0          52s
sof-completions-78jld   0/1     Error       0          34s
sof-completions-7rnfk   0/1     Error       0          47s
...
```

보통의 파드가 Running을 하려는 것과 달리 *Job* 파드는 Completed, Failed 또는 Error 상태로 남아 있습니다. 기본적으로 *Job* 파드가 완료되어도 *Job* 컨트롤러는 파드를 삭제하지 않습니다. 하지만 *Job*에서 완료된 파드를 삭제하도록 설정할 수 있습니다.

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: clean-up-pi
spec:
  parallelism: 3
  template:
    spec:
      containers:
      - name: pi
        image: perl:5.34.0
        command: ["perl",  "-Mbignum=bpi", "-wle", "print bpi(2000)"]
      restartPolicy: Never
  ttlSecondsAfterFinished: 10
  backoffLimit: 4
```

`spec.ttlSecondsAfterFinished` 필드에 파드 실행 완료 후 파드를 삭제할 시간(초)을 설정할 수 있습니다.

```sh
$ k get po -l job-name=clean-up-pi -w
...
clean-up-pi-49qqr   0/1     Completed   0          14s
clean-up-pi-hnkhm   0/1     Completed   0          14s
clean-up-pi-49qqr   0/1     Terminating   0          24s
clean-up-pi-hnkhm   0/1     Terminating   0          24s
...
```

## CronJob
CronJob은 주기적으로 Job을 실행하는 리소스입니다. CronJob은 Cron 스케줄을 지정하여 주기적으로 Job을 실행합니다. CronJob은 Job과 유사한데 Job은 한 번 실행되고 종료되지만 CronJob은 주기적으로 실행됩니다.

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: hello
spec:
  schedule: "*/1 * * * *" # 매 분마다 실행
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: hello
            image: busybox:1.33.1
            args:
            - /bin/sh
            - -c
            - date; echo Certified Kubernetes Trilogy
          restartPolicy: OnFailure
```

```sh
$ k get cj -w
NAME    SCHEDULE      SUSPEND   ACTIVE   LAST SCHEDULE   AGE
hello   */1 * * * *   False     0        <none>          44s
hello   */1 * * * *   False     1        0s              47s
hello   */1 * * * *   False     0        8s              55s
```

`spec.jobTemplate` 필드에 Job 리소스 명세를 정의합니다.
`spec.schedule` 필드에 Cron 스케줄을 지정합니다. Cron 스케줄은 다음과 같은 형식으로 지정합니다.

```sh
# ┌───────────── 분 (0 - 59)
# │ ┌───────────── 시 (0 - 23)
# │ │ ┌───────────── 일 (1 - 31)
# │ │ │ ┌───────────── 월 (1 - 12)
# │ │ │ │ ┌───────────── 요일 (0 - 6) (일요일부터 토요일까지;
# │ │ │ │ │                                   특정 시스템에서는 7도 일요일)
# │ │ │ │ │                                   또는 sun, mon, tue, wed, thu, fri, sat
# │ │ │ │ │
# * * * * *
```

[crontab.guru](https://crontab.guru/)를 사용하면 Cron 스케줄을 쉽게 만들 수 있습니다(**시험에선 사용할 수 없습니다!**).
