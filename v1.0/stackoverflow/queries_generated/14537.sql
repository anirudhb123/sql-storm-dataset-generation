-- Performance Benchmarking Query

WITH UserStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN
        Badges b ON u.Id = b.UserId
    LEFT JOIN
        Votes v ON u.Id = v.UserId
    GROUP BY
        u.Id, u.DisplayName, u.Reputation
),
PostStats AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount
    FROM
        Posts p
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    GROUP BY
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score
),
TopUsers AS (
    SELECT
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        BadgeCount,
        UpVotes,
        DownVotes,
        RANK() OVER (ORDER BY Reputation DESC) AS UserRank
    FROM
        UserStats
),
TopPosts AS (
    SELECT
        PostId,
        Title,
        CreationDate,
        ViewCount,
        Score,
        CommentCount,
        VoteCount,
        RANK() OVER (ORDER BY Score DESC) AS PostRank
    FROM
        PostStats
)

SELECT
    u.DisplayName AS TopUser,
    u.Reputation,
    u.PostCount,
    u.BadgeCount,
    u.UpVotes,
    u.DownVotes,
    p.Title AS TopPost,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    p.CommentCount,
    p.VoteCount
FROM
    TopUsers u
JOIN
    TopPosts p ON u.UserId = p.PostId
WHERE
    u.UserRank <= 10 AND p.PostRank <= 10
ORDER BY
    u.UserRank, p.PostRank;
