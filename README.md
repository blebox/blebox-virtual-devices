# Virtual BleBox devices

11 dockerized BleBox device emulators - designed to help integration developers and maintainers (who may not own actual BleBox devices).

Based on actual [BleBox home automation products](https://blebox.eu/products/?lang=en).

(Only minimal features are implemented - to help quickly and reliably create and test basic integrations).

Based on API docs here: https://technical.blebox.eu


## Usage

1. Create a docker network:
  
```console
$ docker network create blebox_sensors
```

2. Start the devices:

  ```console
  $ docker-compose up
  ```
  
3. List the devices:

  ```console
  $ docker network inspect blebox_sensors
  ```

  or, if you have `jq` installed:

  ```console
  $ docker network inspect blebox_sensors | jq '.[0]["Containers"] | map(.IPv4Address + " " + .Name)'
  ```


## Testing

1. Detect the device:

  ```console
  $ curl -s http://172.20.0.4:80/api/device/state | jq
  ```

  ```json
  {
    "device": {
      "deviceName": "My sauna 1",
      "type": "saunaBox",
      "fv": "0.176",
      "hv": "0.6",
      "apiLevel": "20180604",
      "id": "aafe34db94f7",
      "ip": "172.20.0.4"
    }
  }
  ```

2. Get the status with the product-specific API:

  ```console
  $ curl -s http://172.20.0.4:80/api/heat/state | jq
  ```

  ```json
  {
    "heat": {
      "state": 1,
      "desiredTemp": 7126,
      "sensors": [
        {
          "type": "temperature",
          "id": 0,
          "value": 7126,
          "trend": 0,
          "state": 2,
          "elapsedTimeS": 0
        }
      ]
    }
  }
  ```

3. Interact with the product:

  ```console
  $ curl -d '{"heat": { "state": 1, "desiredTemp": 6300 }}' -si "http://172.20.0.4:80/api/heat/set"
  ```


### Tips

- when stopping the containers, press Ctrl-C twice for faster shutdown

- use the `find_box` script to return the current IP addresses with matching names:

  ```console
  $ find_box "sauna" # prints e.g. 172.20.0.5
  ```

  or, use a command that always works:

  ```console
  $ curl -d '{"heat": { "state": 1, "desiredTemp": 6300 }}' -si "http://$(./find_box 'sauna'):80/api/heat/set"
  ```


### Contributing

The usual. Open an issue, submit a PR, etc.

Please report any differences from the way real BleBox devices behave.
