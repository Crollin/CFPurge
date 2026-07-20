/// <reference types="@raycast/api">

/* 🚧 🚧 🚧
 * This file is auto-generated from the extension's manifest.
 * Do not modify manually. Instead, update the `package.json` file.
 * 🚧 🚧 🚧 */

/* eslint-disable @typescript-eslint/ban-types */

type ExtensionPreferences = {
  /** Token API Cloudflare - Même token que dans CFPurge (Zone > Cache Purge > Edit) */
  "apiToken": string
}

/** Preferences accessible in all the extension's commands */
declare type Preferences = ExtensionPreferences

declare namespace Preferences {
  /** Preferences accessible in the `purge-url` command */
  export type PurgeUrl = ExtensionPreferences & {}
  /** Preferences accessible in the `purge-all` command */
  export type PurgeAll = ExtensionPreferences & {}
}

declare namespace Arguments {
  /** Arguments passed to the `purge-url` command */
  export type PurgeUrl = {}
  /** Arguments passed to the `purge-all` command */
  export type PurgeAll = {}
}

