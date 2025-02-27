WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        pt.Name AS PostType,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.CreationDate DESC) AS rn,
        DENSE_RANK() OVER (ORDER BY p.Score DESC) AS score_rank,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) OVER (PARTITION BY p.Id) AS upvote_count,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) OVER (PARTITION BY p.Id) AS downvote_count
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
PostDetails AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.PostType,
        rp.rn,
        rp.upvote_count,
        rp.downvote_count,
        COALESCE(NULLIF(u.DisplayName, ''), 'Anonymous') AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        COALESCE(b.BadgesCount, 0) AS BadgesCount,
        CASE 
            WHEN rp.Score = 0 THEN 'Neutral'
            WHEN rp.Score > 0 THEN 'Positive'
            ELSE 'Negative'
        END AS ScoreCategory
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Users u ON u.Id = (SELECT OwnerUserId FROM Posts WHERE Id = rp.Id)
    LEFT JOIN 
        (SELECT UserId, COUNT(*) AS BadgesCount FROM Badges GROUP BY UserId) b ON b.UserId = u.Id
    WHERE 
        rp.rn = 1
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes,
        MAX(ph.CreationDate) AS LastHistoryDate
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    pd.Title,
    pd.CreationDate,
    pd.ViewCount,
    pd.UpvoteCount,
    pd.DownvoteCount,
    pd.ScoreCategory,
    COALESCE(phd.HistoryTypes, 'No History') AS PostHistoryTypes,
    pd.OwnerDisplayName,
    pd.OwnerReputation,
    CASE 
        WHEN pd.BadgesCount > 5 THEN 'High Badge Holder'
        WHEN pd.BadgesCount BETWEEN 1 AND 5 THEN 'Moderate Badge Holder'
        ELSE 'No Badges'
    END AS BadgeStatus
FROM 
    PostDetails pd
LEFT JOIN 
    PostHistoryDetails phd ON pd.Id = phd.PostId
WHERE 
    pd.ScoreCategory != 'Negative'
ORDER BY 
    pd.Score DESC NULLS LAST, 
    pd.ViewCount DESC
LIMIT 100;

This SQL query leverages Common Table Expressions (CTEs) to construct a detailed overview of the posts in the Stack Overflow schema. It ranks posts by recent activity while analyzing their scores, upvotes, and downvotes, categorizing them accordingly. It fetches badge counts for the users associated with the posts and compiles a list of any relevant post history types, all while incorporating complex predicates and string expressions to handle NULL values uniquely. The results yield filtered and organized data for further performance benchmarks.
