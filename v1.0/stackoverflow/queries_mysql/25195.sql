
WITH TagCounts AS (
    SELECT 
        tag.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AverageScore
    FROM 
        Tags AS tag
    JOIN 
        Posts AS p 
        ON p.Tags LIKE CONCAT('%<', tag.TagName, '> %')
    GROUP BY 
        tag.TagName
), 
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users AS u
    JOIN 
        Posts AS p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes AS v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
TopTags AS (
    SELECT 
        tc.TagName,
        tc.PostCount,
        tc.TotalViews,
        tc.AverageScore,
        @rank1 := IF(@prev1 = tc.PostCount, @rank1, @rownum1) AS Rank,
        @rownum1 := @rownum1 + 1,
        @prev1 := tc.PostCount
    FROM 
        TagCounts AS tc, (SELECT @rownum1 := 0, @rank1 := 0, @prev1 := NULL) r
    WHERE 
        tc.PostCount > 5
    ORDER BY 
        tc.PostCount DESC
),
TopUsers AS (
    SELECT 
        ue.UserId,
        ue.DisplayName,
        ue.PostsCount,
        ue.TotalViews,
        ue.UpVotes,
        ue.DownVotes,
        @rank2 := IF(@prev2 = ue.TotalViews, @rank2, @rownum2) AS Rank,
        @rownum2 := @rownum2 + 1,
        @prev2 := ue.TotalViews
    FROM 
        UserEngagement AS ue, (SELECT @rownum2 := 0, @rank2 := 0, @prev2 := NULL) r
    WHERE 
        ue.PostsCount > 10
    ORDER BY 
        ue.TotalViews DESC
)
SELECT 
    t.Rank AS TagRank,
    t.TagName,
    t.PostCount,
    t.TotalViews,
    t.AverageScore,
    u.Rank AS UserRank,
    u.DisplayName AS UserName,
    u.PostsCount AS UserPostsCount,
    u.TotalViews AS UserTotalViews,
    u.UpVotes AS UserUpVotes,
    u.DownVotes AS UserDownVotes
FROM 
    TopTags AS t
JOIN 
    TopUsers AS u ON t.TotalViews = u.TotalViews
ORDER BY 
    TagRank, UserRank;
