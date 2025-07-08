
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS rn,
        p.OwnerUserId,
        p.Tags
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        (SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - 
         SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END)) AS NetVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 100
    GROUP BY 
        u.Id, u.Reputation
),
TopTags AS (
    SELECT 
        TagName,
        COUNT(*) AS TagCount
    FROM (
        SELECT TRIM(value) AS TagName
        FROM Posts, LATERAL SPLIT_TO_TABLE(Tags, ',') AS value
        WHERE PostTypeId = 1
    )
    GROUP BY 
        TagName
    ORDER BY 
        TagCount DESC
    LIMIT 10
),
AggregateComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
)
SELECT 
    p.Title,
    p.Score,
    us.UserId,
    us.Reputation,
    us.PostCount,
    us.UpVotes,
    us.DownVotes,
    us.NetVotes,
    tc.TagName,
    ac.CommentCount
FROM 
    RankedPosts p
LEFT JOIN 
    UserStats us ON p.OwnerUserId = us.UserId
LEFT JOIN 
    TopTags tc ON POSITION(tc.TagName IN p.Tags) > 0
LEFT JOIN 
    AggregateComments ac ON p.PostId = ac.PostId
WHERE 
    p.rn = 1 
ORDER BY 
    p.Score DESC, us.Reputation DESC;
