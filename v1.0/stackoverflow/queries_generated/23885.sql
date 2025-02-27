WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS ViewRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
PostWithBadges AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.CreationDate,
        rp.OwnerDisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Badges b ON b.UserId = (
            SELECT u.Id FROM Users u WHERE u.DisplayName = rp.OwnerDisplayName
        )
    GROUP BY 
        rp.PostId, rp.Title, rp.ViewCount, rp.CreationDate, rp.OwnerDisplayName
),
PostsWithComments AS (
    SELECT 
        pwb.PostId,
        pwb.Title,
        pwb.ViewCount,
        pwb.CreationDate,
        pwb.OwnerDisplayName,
        pwb.BadgeCount,
        pc.CommentCount,
        COALESCE(pc.CommentCount, 0) AS TotalComments
    FROM 
        PostWithBadges pwb
    LEFT JOIN (
        SELECT 
            PostId, COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) pc ON pwb.PostId = pc.PostId
)
SELECT 
    pwc.*,
    CASE 
        WHEN TotalComments > 0 THEN 'Commented'
        ELSE 'No Comments'
    END AS CommentStatus,
    CASE
        WHEN BadgeCount = 0 THEN 'No Badges'
        ELSE 'Has Badges'
    END AS BadgeStatus
FROM 
    PostsWithComments pwc
WHERE 
    ViewRank <= 5
ORDER BY 
    pwc.ViewCount DESC;

-- Bonus: Count distinct tags associated with each post, including a bizarre check for posts with a NULL Title
WITH PostTagCounts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(DISTINCT t.TagName) AS TagCount
    FROM 
        Posts p
    LEFT JOIN 
        string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><') AS tag_names ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = tag_names
    GROUP BY 
        p.Id
)
SELECT 
    ptc.PostId,
    ptc.TagCount,
    CASE 
        WHEN ptc.TagCount IS NULL AND p.Title IS NULL THEN 'No Tags and Title'
        ELSE 'Post Data Integrity OK'
    END AS TitleStatus
FROM 
    PostTagCounts ptc
JOIN 
    Posts p ON ptc.PostId = p.Id;

-- Final step: Compute an elaborate metric on the posts that are top-ranked by view count without titles
SELECT 
    pwc.PostId,
    SUM(CASE WHEN p.Title IS NULL THEN 1 ELSE 0 END) AS PostsWithoutTitle,
    AVG(EXTRACT(EPOCH FROM CURRENT_TIMESTAMP - p.CreationDate)) AS AvgAgeInSeconds
FROM 
    PostsWithComments pwc
JOIN 
    Posts p ON pwc.PostId = p.Id
WHERE 
    p.Title IS NULL
GROUP BY 
    pwc.PostId
HAVING 
    SUM(CASE WHEN p.Title IS NULL THEN 1 ELSE 0 END) > 0;
