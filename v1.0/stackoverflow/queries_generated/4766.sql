WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
),
TopPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS Upvotes,
        SUM(v.VoteTypeId = 3) AS Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.CreationDate, p.OwnerUserId
),
PostStats AS (
    SELECT
        tp.PostId,
        tp.Title,
        tp.ViewCount,
        tp.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        tp.CommentCount,
        tp.Upvotes,
        tp.Downvotes,
        COALESCE(w2.AvgScore, 0) AS AvgScore,
        CASE
            WHEN tp.Upvotes - tp.Downvotes > 0 THEN 'Positive'
            WHEN tp.Upvotes - tp.Downvotes < 0 THEN 'Negative'
            ELSE 'Neutral'
        END AS Sentiment
    FROM 
        TopPosts tp
    JOIN 
        Users u ON u.Id = tp.OwnerUserId
    LEFT JOIN (
        SELECT 
            p.Id AS PostId,
            AVG(p.Score) AS AvgScore
        FROM 
            Posts p
        WHERE 
            p.PostTypeId = 2
        GROUP BY 
            p.Id
    ) w2 ON w2.PostId = tp.PostId
),
FinalResult AS (
    SELECT 
        ps.*,
        ur.ReputationRank
    FROM 
        PostStats ps
    JOIN 
        UserReputation ur ON ur.UserId = ps.OwnerUserId
    WHERE 
        ur.ReputationRank <= 10
)
SELECT 
    f.*,
    CASE 
        WHEN f.ReputationRank IS NULL THEN 'Rank Not Available'
        ELSE CONCAT('Rank ', f.ReputationRank)
    END AS RankInfo,
    NULLIF(f.CommentCount, 0) AS SafeCommentCount,
    CONCAT('Max Views: ', GREATEST(f.ViewCount, f.Upvotes + f.Downvotes)) AS MaxEngagement
FROM 
    FinalResult f
ORDER BY 
    f.ViewCount DESC;
