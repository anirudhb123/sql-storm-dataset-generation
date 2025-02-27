WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS ViewRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, p.OwnerUserId
),
UserRankings AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        u.LastAccessDate,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000 -- Users with higher reputation
),
PostHistoryAggergate AS (
    SELECT 
        p.Id AS PostId,
        COUNT(ph.Id) AS HistoryCount,
        MAX(ph.CreationDate) AS LastEdited
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id
)
SELECT 
    pr.PostId,
    pr.Title,
    pr.CreationDate,
    pr.Score,
    pr.ViewCount,
    pr.AnswerCount,
    pr.CommentCount,
    ur.DisplayName AS OwnerDisplayName,
    ur.Reputation AS OwnerReputation,
    ur.ReputationRank AS OwnerReputationRank,
    pha.HistoryCount,
    pha.LastEdited,
    (
        SELECT 
            STRING_AGG(tag.TagName, ', ') 
        FROM 
            Tags tag
        WHERE 
            tag.WikiPostId = 
            (SELECT TOP 1 WikiPostId FROM Tags WHERE Id IN (SELECT unnest(string_to_array(p.Tags, ','))::int)) 
    ) AS RelatedTags
FROM 
    RankedPosts pr
JOIN 
    Users u ON pr.OwnerUserId = u.Id
JOIN 
    UserRankings ur ON u.Id = ur.UserId
LEFT JOIN 
    PostHistoryAggergate pha ON pr.PostId = pha.PostId
WHERE 
    pr.Score > 10 
    AND ur.ReputationRank <= 50 -- Top 50 users based on reputation
ORDER BY 
    pr.Score DESC, 
    pr.ViewCount DESC;

