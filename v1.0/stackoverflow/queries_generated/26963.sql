WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.AnswerCount,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Tags,
        OwnerDisplayName,
        CreationDate,
        Score,
        ViewCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5 -- Top 5 posts per tag
),
TagUsage AS (
    SELECT 
        UNNEST(string_to_array(Tags, '>')) AS TagName
    FROM 
        TopPosts
),
TagCounts AS (
    SELECT 
        TagName,
        COUNT(*) AS PostCount
    FROM 
        TagUsage
    GROUP BY 
        TagName
    ORDER BY 
        PostCount DESC
),
UserBadges AS (
    SELECT 
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.DisplayName
),
UserPosts As (
    SELECT 
        u.DisplayName,
        COUNT(p.Id) AS UserPostCount
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.DisplayName
),
FinalStats AS (
    SELECT 
        tc.TagName,
        tc.PostCount,
        ub.BadgeCount,
        up.UserPostCount
    FROM 
        TagCounts tc
    LEFT JOIN 
        UserBadges ub ON ub.BadgeCount IS NOT NULL
    LEFT JOIN 
        UserPosts up ON up.UserPostCount IS NOT NULL
)
SELECT 
    fs.TagName,
    fs.PostCount,
    COALESCE(fs.BadgeCount, 0) AS BadgeCount,
    COALESCE(fs.UserPostCount, 0) AS TotalPostsByUser
FROM 
    FinalStats fs
ORDER BY 
    fs.PostCount DESC;
