
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS OwnerRank,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) OVER (PARTITION BY p.Id) AS UpvoteCount,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) OVER (PARTITION BY p.Id) AS DownvoteCount
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR)
),
LatestBadges AS (
    SELECT 
        b.UserId,
        b.Name AS BadgeName,
        ROW_NUMBER() OVER (PARTITION BY b.UserId ORDER BY b.Date DESC) AS BadgeRank
    FROM 
        Badges b
),
PopularTags AS (
    SELECT 
        T.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags T
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', T.TagName, '%')
    GROUP BY 
        T.TagName
    HAVING 
        COUNT(p.Id) > 10
)
SELECT 
    rp.Title,
    rp.OwnerDisplayName,
    rb.BadgeName,
    rp.Score AS PostScore,
    rp.ViewCount,
    pt.TagName,
    (rp.UpvoteCount - rp.DownvoteCount) AS NetVotes,
    rp.CreationDate
FROM 
    RankedPosts rp
LEFT JOIN 
    LatestBadges rb ON rp.OwnerUserId = rb.UserId AND rb.BadgeRank = 1
JOIN 
    PopularTags pt ON rp.Title LIKE CONCAT('%', pt.TagName, '%')
WHERE 
    rp.OwnerRank <= 3
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC
LIMIT 10 OFFSET 5;
