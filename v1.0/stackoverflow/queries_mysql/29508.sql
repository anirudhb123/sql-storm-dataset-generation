
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        @rownum := IF(@prev_owner = p.OwnerUserId, @rownum + 1, 1) AS PostRank,
        @prev_owner := p.OwnerUserId
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    CROSS JOIN (SELECT @rownum := 0, @prev_owner := NULL) r
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
    ORDER BY 
        p.OwnerUserId, p.CreationDate DESC
),
PostStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Tags,
        rp.OwnerDisplayName,
        rp.CreationDate,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Comments c ON rp.PostId = c.PostId
    LEFT JOIN 
        Votes v ON rp.PostId = v.PostId
    GROUP BY 
        rp.PostId, rp.Title, rp.Body, rp.Tags, rp.OwnerDisplayName, rp.CreationDate
),
FilteredPosts AS (
    SELECT 
        ps.*,
        @score_rank := @score_rank + 1 AS ScoreRank
    FROM 
        PostStats ps
    CROSS JOIN (SELECT @score_rank := 0) s
    WHERE 
        ps.CommentCount > 0 
    ORDER BY 
        ps.UpVotes - ps.DownVotes DESC, ps.CommentCount DESC, ps.TotalBounties DESC
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Body,
    fp.Tags,
    fp.OwnerDisplayName,
    fp.CreationDate,
    fp.UpVotes,
    fp.DownVotes,
    fp.CommentCount,
    fp.TotalBounties,
    fp.ScoreRank
FROM 
    FilteredPosts fp
WHERE 
    fp.ScoreRank <= 10 
ORDER BY 
    fp.ScoreRank;
