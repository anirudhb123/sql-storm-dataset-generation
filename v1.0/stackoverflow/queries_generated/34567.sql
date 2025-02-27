WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerName,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
        AND p.PostTypeId IN (1, 2)  -- Considering only Questions and Answers
),
PostWithTags AS (
    SELECT 
        r.PostId,
        r.Title,
        r.CreationDate,
        r.ViewCount,
        r.OwnerName,
        STUFF((
            SELECT ', ' + t.TagName
            FROM Tags t
            INNER JOIN STRING_SPLIT(p.Tags, ',') tagSplit ON t.TagName = LTRIM(RTRIM(tagSplit.value))
            WHERE p.Id = r.PostId
            FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, '') AS Tags
    FROM 
        RankedPosts r
    JOIN 
        Posts p ON r.PostId = p.Id
),
PostStats AS (
    SELECT 
        p.PostId,
        p.Title,
        p.ViewCount,
        COALESCE(AVG(v.BountyAmount), 0) AS AverageBounty,
        COUNT(c.Id) AS CommentCount,
        COUNT(b.Id) AS BadgeCount
    FROM 
        PostWithTags p
    LEFT JOIN 
        Votes v ON p.PostId = v.PostId AND v.VoteTypeId = 8  -- BountyStart votes
    LEFT JOIN 
        Comments c ON p.PostId = c.PostId
    LEFT JOIN 
        Badges b ON p.OwnerName = (SELECT DisplayName FROM Users WHERE Id = b.UserId)
    GROUP BY 
        p.PostId, p.Title, p.ViewCount
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.ViewCount,
    ps.AverageBounty,
    ps.CommentCount,
    pt.Tags
FROM 
    PostStats ps
JOIN 
    PostWithTags pt ON ps.PostId = pt.PostId
WHERE 
    ps.AverageBounty > 0 
ORDER BY 
    ps.ViewCount DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;  -- Fetching the top 10 based on view count
