WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.Score,
        COALESCE(SUM(v.VoteTypeId = 2) OVER (PARTITION BY p.Id), 0) AS Upvotes, 
        COALESCE(SUM(v.VoteTypeId = 3) OVER (PARTITION BY p.Id), 0) AS Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
    ORDER BY 
        p.CreationDate DESC
)
SELECT 
    u.DisplayName,
    u.Reputation,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.AnswerCount,
    rp.Score,
    rp.Upvotes,
    rp.Downvotes,
    CASE 
        WHEN rp.Upvotes > rp.Downvotes THEN 'Positive Feedback'
        WHEN rp.Downvotes > rp.Upvotes THEN 'Negative Feedback'
        ELSE 'Neutral Feedback'
    END AS FeedbackType,
    (SELECT string_agg(t.TagName, ', ') 
     FROM Tags t 
     WHERE t.WikiPostId IN (SELECT Tags.WikiPostId FROM Posts WHERE Id = rp.PostId)) AS AssociatedTags
FROM 
    RecentPosts rp
JOIN 
    UserReputation u ON rp.OwnerUserId = u.UserId
WHERE 
    u.ReputationRank <= 10
ORDER BY 
    rp.Score DESC
LIMIT 50;
