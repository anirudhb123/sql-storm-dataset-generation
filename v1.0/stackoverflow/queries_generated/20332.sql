WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS Owner,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS OwnerPostRank,
        COUNT(c.Id) FILTER (WHERE c.PostId IS NOT NULL) OVER (PARTITION BY p.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) OVER (PARTITION BY p.Id) AS UpVoteCount,
        SUM(v.VoteTypeId = 3) OVER (PARTITION BY p.Id) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= '2023-01-01'
),

PostsHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS HistoryDate,
        pht.Name AS HistoryType,
        STRING_AGG(CASE WHEN ph.Comment IS NOT NULL THEN ph.Comment ELSE 'No Comment' END, '; ') AS EditComments
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        ph.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        ph.PostId, HistoryDate, HistoryType
),

PostsWithComments AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Owner,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        rp.UpVoteCount,
        rp.DownVoteCount,
        ph.HistoryDate,
        ph.HistoryType,
        ph.EditComments
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostsHistory ph ON rp.PostId = ph.PostId
    WHERE 
        rp.CommentCount > 0 OR ph.HistoryType IS NOT NULL
)

SELECT 
    pwc.PostId,
    pwc.Title,
    pwc.Owner,
    pwc.CreationDate,
    pwc.Score,
    pwc.ViewCount,
    pwc.CommentCount,
    pwc.UpVoteCount,
    pwc.DownVoteCount,
    COALESCE(pwc.EditComments, 'No Edits') AS EditHistory,
    CASE 
        WHEN pwc.Score IS NULL THEN 'Unscored Post'
        WHEN pwc.Score < 0 THEN 'Negative Score'
        ELSE 'Positive Score'
    END AS ScoreCategory,
    CASE 
        WHEN pwc.ViewCount < 50 THEN 'Low Views'
        WHEN pwc.ViewCount BETWEEN 50 AND 200 THEN 'Medium Views'
        ELSE 'High Views'
    END AS ViewCategory
FROM 
    PostsWithComments pwc
ORDER BY 
    pwc.CreationDate DESC
LIMIT 100;
