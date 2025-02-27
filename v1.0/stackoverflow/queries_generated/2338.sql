WITH RecentPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PopularTags AS (
    SELECT 
        UNNEST(string_to_array(Tags, '><')) AS Tag,
        COUNT(*) AS TagCount
    FROM 
        Posts
    WHERE 
        Tags IS NOT NULL
    GROUP BY 
        Tag
    ORDER BY 
        TagCount DESC
    LIMIT 10
)
SELECT 
    rp.Title,
    rp.CreationDate,
    us.DisplayName,
    us.UpVoteCount,
    us.DownVoteCount,
    CASE 
        WHEN us.UpVoteCount + us.DownVoteCount = 0 THEN 0 
        ELSE ROUND((us.UpVoteCount::DECIMAL / (us.UpVoteCount + us.DownVoteCount)) * 100, 2) 
    END AS UpVotePercentage,
    pt.Tag,
    pt.TagCount
FROM 
    RecentPosts rp
JOIN 
    UserStats us ON rp.OwnerUserId = us.UserId
LEFT JOIN 
    PopularTags pt ON rp.Tags LIKE '%' || pt.Tag || '%'
WHERE 
    rp.PostRank = 1
ORDER BY 
    rp.CreationDate DESC
LIMIT 50;
