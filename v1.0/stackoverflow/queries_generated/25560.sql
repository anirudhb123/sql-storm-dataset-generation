WITH TagStats AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore,
        COUNT(DISTINCT c.Id) AS CommentCount,
        AVG(v.BountyAmount) AS AverageBounty
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[]) 
    LEFT JOIN 
        Comments c ON p.Id = c.PostId 
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) -- BountyStart, BountyClose
    GROUP BY 
        t.TagName
),
TopTags AS (
    SELECT 
        ts.TagName,
        ts.PostCount,
        ts.TotalViews,
        ts.TotalScore,
        ts.CommentCount,
        ts.AverageBounty,
        RANK() OVER (ORDER BY ts.TotalScore DESC) AS ScoreRank,
        RANK() OVER (ORDER BY ts.TotalViews DESC) AS ViewRank
    FROM 
        TagStats ts
),
UserEngagement AS (
    SELECT 
        u.DisplayName,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(p.Score) AS TotalPostScore,
        SUM(c.Score) AS TotalCommentScore,
        COUNT(DISTINCT p.Id) AS PostCreated,
        COUNT(DISTINCT c.Id) AS CommentsMade
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    GROUP BY 
        u.DisplayName
)
SELECT 
    tt.TagName,
    tt.PostCount,
    tt.TotalViews,
    tt.TotalScore,
    tt.CommentCount,
    tt.AverageBounty,
    ue.DisplayName,
    ue.BadgeCount,
    ue.TotalPostScore,
    ue.TotalCommentScore,
    ue.PostCreated,
    ue.CommentsMade
FROM 
    TopTags tt
JOIN 
    UserEngagement ue ON tt.TagName = ANY(string_to_array(substring((SELECT array_agg(t.TagName) FROM Tags t WHERE t.Id IN (SELECT UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[]))) ORDER BY t.Count DESC LIMIT 5), ',', 2) '' AS Text)
ORDER BY 
    tt.TotalScore DESC, ue.TotalPostScore DESC;
