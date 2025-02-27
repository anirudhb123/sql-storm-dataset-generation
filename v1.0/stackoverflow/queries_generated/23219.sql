WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        SUM(b.Class) AS TotalBadgeValue,
        MAX(u.Reputation) AS MaxReputation
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
CommentStats AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS TotalComments,
        MAX(c.CreationDate) AS LastCommentDate
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
PostWithComments AS (
    SELECT 
        rp.PostId,
        rp.Title,
        COALESCE(cs.TotalComments, 0) AS TotalComments,
        COALESCE(cs.LastCommentDate, '1970-01-01') AS LastCommentDate,
        rp.CreationDate,
        rp.Score
    FROM 
        RankedPosts rp
    LEFT JOIN 
        CommentStats cs ON rp.PostId = cs.PostId
    WHERE 
        rp.RecentPostRank = 1
)
SELECT 
    pwc.PostId,
    pwc.Title,
    pwc.TotalComments,
    pwc.LastCommentDate,
    COALESCE(ur.MaxReputation, 0) AS UserReputation,
    pwc.Score,
    CASE 
        WHEN pwc.Score > 0 THEN 'Positive'
        WHEN pwc.Score < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS Sentiment,
    DENSE_RANK() OVER (ORDER BY pwc.Score DESC) AS ScoreRank
FROM 
    PostWithComments pwc
LEFT JOIN 
    Users u ON u.Id = (SELECT OwnerUserId FROM Posts WHERE Id = pwc.PostId)
LEFT JOIN 
    UserReputation ur ON u.Id = ur.UserId
ORDER BY 
    ScoreRank, TotalComments DESC;

-- Further complexity and results manipulation:
WITH FinalResults AS (
    SELECT 
        *,
        CASE 
            WHEN TotalComments > 5 THEN 'Highly Engaged'
            ELSE 'Low Engagement' 
        END AS EngagementLevel
    FROM 
        (SELECT 
            pwc.*,
            COUNT(*) OVER (PARTITION BY pwc.UserReputation ORDER BY pwc.UserReputation DESC) AS ReputationRank
        FROM 
            PostWithComments pwc) AS RankedPostsWithEngagement
)
SELECT 
    PostId,
    Title,
    Sentiment,
    CASE 
        WHEN EngagementLevel = 'Highly Engaged' THEN 'Share on Social Media'
        ELSE 'Review Engagement Strategy'
    END AS SuggestedAction
FROM 
    FinalResults
WHERE 
    LastCommentDate >= NOW() - INTERVAL '30 days' 
    AND UserReputation > (SELECT AVG(MaxReputation) FROM UserReputation)
ORDER BY 
    UserReputation DESC, Sentiment DESC, Title;
