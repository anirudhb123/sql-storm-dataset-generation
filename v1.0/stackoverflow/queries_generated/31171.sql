WITH RecursivePostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVoteCount,
        COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVoteCount,
        MAX(b.Date) AS LastBadgeDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    WHERE 
        p.PostTypeId IN (1, 2) -- Considering only Questions and Answers
    GROUP BY 
        p.Id
),
RankedPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.OwnerUserId,
        ps.CreationDate,
        ps.CommentCount,
        ps.UpVoteCount,
        ps.DownVoteCount,
        ps.LastBadgeDate,
        RANK() OVER (PARTITION BY ps.OwnerUserId ORDER BY ps.CommentCount DESC, ps.UpVoteCount DESC) AS PostRank
    FROM 
        RecursivePostStats ps
),
PostLinksSummary AS (
    SELECT 
        pl.PostId,
        COUNT(DISTINCT pl.RelatedPostId) AS RelatedPostCount
    FROM 
        PostLinks pl
    GROUP BY 
        pl.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    u.DisplayName AS OwnerDisplayName,
    rp.CommentCount,
    rp.UpVoteCount,
    rp.DownVoteCount,
    COALESCE(pl.RelatedPostCount, 0) AS RelatedPostCount,
    rp.LastBadgeDate,
    CASE 
        WHEN rp.LastBadgeDate IS NOT NULL AND rp.LastBadgeDate > NOW() - INTERVAL '1 year' THEN 'Active'
        ELSE 'InActive'
    END AS UserActivityStatus
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    PostLinksSummary pl ON rp.PostId = pl.PostId
WHERE 
    rp.PostRank = 1 
AND 
    (rp.CommentCount > 5 OR rp.UpVoteCount > 10)
ORDER BY 
    UserActivityStatus DESC,
    rp.PostId;
