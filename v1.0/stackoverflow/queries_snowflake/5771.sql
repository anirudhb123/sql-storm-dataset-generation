
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.ClosedDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        u.DisplayName AS OwnerDisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.CreationDate >= DATEADD(year, -1, '2024-10-01')
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, p.ClosedDate, u.DisplayName, p.OwnerUserId
),
PostWithBadges AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        rp.ClosedDate,
        rp.OwnerDisplayName,
        rb.Name AS BadgeName,
        rb.Class,
        rb.Date AS BadgeDate,
        rp.TotalUpvotes,
        rp.TotalDownvotes,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Badges rb ON rp.OwnerDisplayName = (SELECT DisplayName FROM Users WHERE Id = rb.UserId)
    LEFT JOIN 
        Comments c ON rp.PostId = c.PostId
    WHERE 
        rp.Rank <= 5
    GROUP BY 
        rp.PostId, rp.Title, rp.CreationDate, rp.Score, rp.ViewCount, rp.AnswerCount, 
        rp.ClosedDate, rp.OwnerDisplayName, rb.Name, rb.Class, rb.Date, 
        rp.TotalUpvotes, rp.TotalDownvotes
)
SELECT 
    pwb.PostId,
    pwb.Title,
    pwb.OwnerDisplayName,
    pwb.CreationDate,
    pwb.Score,
    pwb.ViewCount,
    pwb.AnswerCount,
    pwb.ClosedDate,
    pwb.BadgeName,
    pwb.Class,
    pwb.BadgeDate,
    pwb.TotalUpvotes,
    pwb.TotalDownvotes,
    pwb.CommentCount
FROM 
    PostWithBadges pwb
ORDER BY 
    pwb.Score DESC, pwb.TotalUpvotes DESC
LIMIT 100;
