WITH UserBadgeStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadgeCount,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadgeCount,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadgeCount,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes,
        SUM(u.Views) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        GoldBadgeCount,
        SilverBadgeCount,
        BronzeBadgeCount,
        TotalUpVotes,
        TotalDownVotes,
        TotalViews,
        RANK() OVER (ORDER BY TotalUpVotes DESC) AS UpVoteRank,
        RANK() OVER (ORDER BY TotalViews DESC) AS ViewRank
    FROM 
        UserBadgeStats
),
PopularTags AS (
    SELECT 
        unnest(string_to_array(substring(Posts.Tags, 2, length(Posts.Tags)-2), '><')) AS Tag,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
    GROUP BY 
        Tag
    ORDER BY 
        PostCount DESC
    LIMIT 5
),
UserPosts AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS UserPostCount,
        AVG(p.Score) AS AvgPostScore,
        SUM(CASE WHEN p.ViewCount > 100 THEN 1 ELSE 0 END) AS HighViewCountPosts
    FROM 
        Posts p
    WHERE 
        p.PostTypeId IN (1, 2) -- Questions and Answers
    GROUP BY 
        p.OwnerUserId
)

SELECT 
    u.DisplayName AS UserName,
    u.GoldBadgeCount,
    u.SilverBadgeCount,
    u.BronzeBadgeCount,
    u.TotalUpVotes,
    u.TotalDownVotes,
    u.TotalViews,
    tp.UserPostCount,
    tp.AvgPostScore,
    tp.HighViewCountPosts,
    STRING_AGG(pt.Tag, ', ') AS PopularTags
FROM 
    TopUsers u
JOIN 
    UserPosts tp ON u.UserId = tp.OwnerUserId
CROSS JOIN 
    PopularTags pt
WHERE 
    u.UpVoteRank <= 10 OR u.ViewRank <= 10
GROUP BY 
    u.UserId, u.DisplayName, u.GoldBadgeCount, u.SilverBadgeCount, u.BronzeBadgeCount, tp.UserPostCount, tp.AvgPostScore, tp.HighViewCountPosts
ORDER BY 
    u.TotalUpVotes DESC, u.TotalViews DESC;
