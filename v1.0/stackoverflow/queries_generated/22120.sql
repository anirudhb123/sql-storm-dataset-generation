WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.PostTypeId,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        ARRAY(SELECT DISTINCT unnest(string_to_array(p.Tags, '>')) ORDER BY 1) AS TagArray
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        COUNT(down.Id) AS DownVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes down ON p.Id = down.PostId AND down.VoteTypeId = 3
    GROUP BY 
        u.Id
),
PostHistoryWithReason AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserDisplayName,
        ph.Comment,
        COALESCE(cr.Name, 'No Reason') AS CloseReason
    FROM 
        PostHistory ph
    LEFT JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id AND ph.PostHistoryTypeId = 10
)
SELECT 
    p.Id AS PostId,
    p.Title,
    u.UserId,
    u.DisplayName AS UserDisplayName,
    ra.TagArray,
    pa.RankScore,
    COALESCE(uh.DownVoteCount, 0) AS DownVotes,
    COALESCE(uh.UpVoteCount, 0) AS UpVotes,
    ph.CloseReason,
    CASE 
        WHEN ph.Comment IS NOT NULL THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus,
    COUNT(c.Id) AS CommentCount
FROM 
    RankedPosts pa
INNER JOIN 
    Posts p ON p.Id = pa.Id
LEFT JOIN 
    UserActivity uh ON p.OwnerUserId = uh.UserId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    PostHistoryWithReason ph ON ph.PostId = p.Id
WHERE 
    p.PostTypeId = 1
AND 
    (p.Score > 0 OR ph.CloseReason IS NOT NULL)
GROUP BY 
    p.Id, u.UserId, ph.CloseReason, ra.TagArray, pa.RankScore, u.DisplayName
HAVING 
    COUNT(c.Id) > 5
ORDER BY 
    p.Score DESC NULLS LAST, 
    pa.RankScore ASC;
