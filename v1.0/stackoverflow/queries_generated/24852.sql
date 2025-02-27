WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS PositiveVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS NegativeVoteCount
    FROM 
        Posts p 
        LEFT JOIN Comments c ON p.Id = c.PostId
        LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.OwnerUserId
),
RecentPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CreationDate,
        rp.CommentCount,
        rp.PositiveVoteCount,
        rp.NegativeVoteCount,
        COALESCE(u.DisplayName, 'Anonymous') AS OwnerDisplayName,
        CASE 
            WHEN rp.Score > 0 THEN 'Popular'
            WHEN rp.Score < 0 THEN 'Unpopular'
            ELSE 'Neutral'
        END AS Popularity
    FROM 
        RankedPosts rp
        LEFT JOIN Users u ON u.Id = (SELECT MIN(OwnerUserId) FROM Posts WHERE Id = rp.PostId) -- Correlated Subquery
    WHERE 
        rp.PostRank = 1
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.CommentCount,
        rp.PositiveVoteCount,
        rp.NegativeVoteCount,
        rp.OwnerDisplayName,
        rp.Popularity,
        (SELECT STRING_AGG(DISTINCT SUBSTRING(Tags FROM 2 FOR LENGTH(Tags) - 2), ', ') 
         FROM UNNEST(string_to_array(rp.Tags, '><')) AS Tags) AS TagsList
    FROM 
        RecentPosts rp 
)
SELECT 
    pd.*, 
    CASE 
        WHEN pd.CommentCount IS NULL THEN 'No comments yet'
        WHEN pd.CommentCount > 0 AND pd.PositiveVoteCount = 0 THEN 'Needs attention'
        ELSE 'Active discussion'
    END AS CommentStatus,
    (SELECT 
        STRING_AGG(DISTINCT ph.Comment || ' - ' || ph.CreationDate::date, '; ')
     FROM 
        PostHistory ph 
     WHERE 
        ph.PostId = pd.PostId 
     AND 
        ph.PostHistoryTypeId IN (10, 11, 12)) AS RecentHistoryEvents
FROM 
    PostDetails pd
ORDER BY 
    pd.CreationDate DESC
LIMIT 100
OFFSET 0; 
