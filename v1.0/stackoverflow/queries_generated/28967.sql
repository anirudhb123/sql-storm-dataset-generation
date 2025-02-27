WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.AnswerCount,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Questions only
        AND p.CreationDate >= NOW() - INTERVAL '1 year' -- Within the last year
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(pt.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%<', t.TagName, '>%') -- Matches tags
    JOIN 
        PostTypes pt ON pt.Id = p.PostTypeId
    WHERE 
        pt.Id IN (1, 2) -- Questions or Answers
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(pt.Id) >= 10 -- Tags associated with at least 10 posts
),
TopUsersWithBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    WHERE 
        u.Reputation > 1000 -- Users with a reputation greater than 1000
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(b.Id) > 0 -- Users with at least one badge
    ORDER BY 
        BadgeCount DESC
    LIMIT 5 -- Top 5 users
)
SELECT 
    rp.OwnerDisplayName,
    rp.Title,
    rp.ViewCount,
    rp.CreationDate,
    pt.TagName,
    t.UserId,
    t.DisplayName AS TopUserDisplayName,
    t.BadgeCount
FROM 
    RankedPosts rp
JOIN 
    PostLinks pl ON pl.PostId = rp.PostId
JOIN 
    PopularTags pt ON pt.TagName = SUBSTRING_INDEX(SUBSTRING_INDEX(rp.Tags, '>', -1), '<', 1) -- Extract first tag
JOIN 
    TopUsersWithBadges t ON t.UserId = rp.OwnerUserId
WHERE 
    rp.Rank <= 3 -- Get top 3 posts per user
ORDER BY 
    rp.ViewCount DESC, 
    rp.CreationDate ASC;
