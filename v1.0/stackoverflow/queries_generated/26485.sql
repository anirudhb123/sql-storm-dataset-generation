WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.Score,
        STRING_AGG(t.TagName, ', ') AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON t.Id = ANY(STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><')::int[])
    WHERE 
        p.CreationDate >= (CURRENT_DATE - INTERVAL '30 days') 
        AND p.PostTypeId = 1  -- Only questions
    GROUP BY 
        p.Id, p.OwnerUserId, p.Title, p.Body, p.CreationDate, p.ViewCount, p.AnswerCount, p.CommentCount, p.Score
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.Views,
        u.UpVotes,
        u.DownVotes
    FROM 
        Users u
    WHERE 
        u.Reputation > 500 -- Focusing only on higher reputation users
),
PostMetrics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Tags,
        rp.CreationDate,
        rp.ViewCount,
        rp.AnswerCount,
        rp.CommentCount,
        rp.Score,
        ur.DisplayName AS UserDisplayName,
        ur.Reputation AS UserReputation,
        ur.Views AS UserViews,
        ur.UpVotes AS UserUpVotes,
        ur.DownVotes AS UserDownVotes
    FROM 
        RankedPosts rp
    JOIN 
        UserReputation ur ON ur.UserId = rp.OwnerUserId
    WHERE 
        rp.PostRank = 1 -- Select only the latest post for each user
)
SELECT 
    pm.Title,
    pm.Tags,
    pm.CreationDate,
    pm.ViewCount,
    pm.AnswerCount,
    pm.CommentCount,
    pm.Score,
    pm.UserDisplayName,
    pm.UserReputation,
    pm.UserViews,
    pm.UserUpVotes,
    pm.UserDownVotes,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = pm.PostId) AS TotalComments
FROM 
    PostMetrics pm
ORDER BY 
    pm.CreationDate DESC
LIMIT 10;
