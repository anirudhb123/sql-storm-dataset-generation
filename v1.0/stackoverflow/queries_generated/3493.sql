WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= DATEADD(year, -1, GETDATE()) 
        AND p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId, u.DisplayName, p.Score
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.OwnerDisplayName,
        rp.Score,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.UserRank <= 5
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.OwnerDisplayName,
    fp.Score,
    fp.CommentCount,
    COALESCE(b.Name, 'No Badge') AS UserBadge
FROM 
    FilteredPosts fp
LEFT JOIN 
    Badges b ON fp.OwnerUserId = b.UserId AND b.Class = 1
ORDER BY 
    fp.Score DESC
FETCH FIRST 10 ROWS ONLY;

WITH PostVoteCounts AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Score,
    pvc.UpVotesCount,
    pvc.DownVotesCount
FROM 
    FilteredPosts fp
JOIN 
    PostVoteCounts pvc ON fp.PostId = pvc.PostId
WHERE 
    abs(pvc.UpVotesCount - pvc.DownVotesCount) > 5;
