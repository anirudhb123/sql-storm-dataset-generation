WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.PostTypeId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '2 years'
), 
PostInteractions AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 6 THEN 1 ELSE 0 END), 0) AS CloseVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
PostHistoryData AS (
    SELECT 
        ph.PostId,
        pht.Name AS HistoryType,
        ph.CreationDate AS HistoryCreationDate,
        ph.UserDisplayName,
        ph.Comment
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '1 year'
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    pi.CommentCount,
    pi.UpVoteCount,
    pi.DownVoteCount,
    pi.CloseVoteCount,
    STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes,
    COUNT(DISTINCT CASE WHEN pht.UserDisplayName IS NOT NULL THEN pht.UserDisplayName END) AS UniqueEditors,
    SUM(CASE 
        WHEN p.CreationDate < NOW() - INTERVAL '6 months' AND pi.CloseVoteCount > 0 
        THEN 1 ELSE 0 END) AS PostsClosedInLast6Months
FROM 
    RankedPosts rp
LEFT JOIN 
    PostInteractions pi ON rp.PostId = pi.PostId
LEFT JOIN 
    PostHistoryData pht ON rp.PostId = pht.PostId
GROUP BY 
    rp.PostId, rp.Title, rp.ViewCount
HAVING 
    COUNT(pi.CommentCount) > 5 
    AND SUM(pi.UpVoteCount - pi.DownVoteCount) > 10
ORDER BY 
    rp.ViewCount DESC
LIMIT 100;
