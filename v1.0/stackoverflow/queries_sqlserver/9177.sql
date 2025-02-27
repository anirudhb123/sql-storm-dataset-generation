
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(DISTINCT t.TagName, ',') AS TagsArray,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate ASC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    CROSS APPLY 
        STRING_SPLIT(p.Tags, '<>') AS t
    WHERE 
        p.CreationDate >= DATEADD(DAY, -30, '2024-10-01')
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, u.DisplayName
), 
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.TagsArray
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 5
)
SELECT 
    pp.PostId,
    pp.Title,
    pp.CreationDate,
    pp.ViewCount,
    pp.Score,
    pp.OwnerDisplayName,
    pp.CommentCount,
    pp.TagsArray,
    (SELECT COUNT(DISTINCT ph.UserId) 
     FROM PostHistory ph 
     WHERE ph.PostId = pp.PostId AND ph.PostHistoryTypeId IN (10, 11, 12, 13)) AS CloseActionCount,
    (SELECT COUNT(DISTINCT v.UserId) 
     FROM Votes v 
     WHERE v.PostId = pp.PostId AND v.VoteTypeId = 2) AS UpvoteCount
FROM 
    TopPosts pp
ORDER BY 
    pp.Score DESC, pp.CreationDate ASC;
