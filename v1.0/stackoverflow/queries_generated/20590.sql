WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.OwnerUserId, 
        p.Score, 
        COUNT(DISTINCT c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' AND 
        p.PostTypeId IN (1, 2)  -- Only questions and answers
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId, p.Score
), FilteredPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.CreationDate, 
        rp.OwnerUserId, 
        rp.Score, 
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank = 1
), UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation, 
        u.Views, 
        u.UpVotes, 
        u.DownVotes,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000
), CommentsStatistics AS (
    SELECT 
        p.Id AS PostId, 
        AVG(c.Score) AS AvgCommentScore, 
        COUNT(c.Id) AS TotalComments
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    ur.DisplayName AS OwnerDisplayName,
    COALESCE(ur.Reputation, 0) AS OwnerReputation,
    COALESCE(cs.AvgCommentScore, 0) AS AvgCommentScore,
    cs.TotalComments,
    CASE 
        WHEN ur.Reputation IS NULL THEN 'Unknown'
        ELSE CASE 
            WHEN ur.Reputation < 2000 THEN 'New Contributor'
            WHEN ur.Reputation < 5000 THEN 'Regular Contributor'
            ELSE 'Top Contributor'
        END
    END AS ContributorLevel
FROM 
    FilteredPosts fp
LEFT JOIN 
    UserReputation ur ON fp.OwnerUserId = ur.UserId
LEFT JOIN 
    CommentsStatistics cs ON fp.PostId = cs.PostId
WHERE 
    (fp.CommentCount > 0 OR ur.Reputation IS NOT NULL)
ORDER BY 
    fp.CreationDate DESC
LIMIT 100;

WITH PostHistoryWithTypes AS (
    SELECT 
        ph.PostId, 
        PHT.Name AS HistoryType, 
        ph.CreationDate AS HistoryCreationDate,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes PHT ON ph.PostHistoryTypeId = PHT.Id
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '6 months'
)
SELECT 
    fp.PostId,
    COUNT(CASE WHEN ph.HistoryRank = 1 THEN 1 END) AS LatestActionCount,
    COUNT(CASE WHEN ph.HistoryType = 'Post Closed' THEN 1 END) AS ClosedPostCount,
    COUNT(CASE WHEN ph.HistoryType = 'Edit Body' OR ph.HistoryType = 'Edit Title' THEN 1 END) AS EditCount
FROM 
    FilteredPosts fp
LEFT JOIN 
    PostHistoryWithTypes ph ON fp.PostId = ph.PostId
GROUP BY 
    fp.PostId;
