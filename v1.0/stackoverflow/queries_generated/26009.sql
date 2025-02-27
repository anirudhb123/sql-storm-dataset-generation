WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Considering only Questions
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
TopQuestions AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.Tags,
        ub.BadgeCount,
        ub.BadgeNames
    FROM 
        RankedPosts rp
    JOIN 
        UserBadges ub ON rp.OwnerUserId = ub.UserId
    WHERE 
        rp.Rank <= 5  -- Top 5 questions per user
),
PopularTags AS (
    SELECT 
        UNNEST(string_to_array(Tags, '><')) AS TagName,  -- Splitting tags into individual records
        COUNT(*) AS TagCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
    GROUP BY 
        UNNEST(string_to_array(Tags, '><'))
    ORDER BY 
        TagCount DESC
    LIMIT 10  -- Top 10 popular tags
)
SELECT 
    tq.PostId,
    tq.Title,
    tq.CreationDate,
    tq.Score,
    tq.BadgeCount,
    tq.BadgeNames,
    pt.TagName,
    pt.TagCount
FROM 
    TopQuestions tq
JOIN 
    PopularTags pt ON pt.TagName IN (SELECT UNNEST(string_to_array(tq.Tags, '><')))  -- Filtering questions by popular tags
ORDER BY 
    tq.Score DESC, tq.CreationDate DESC;
