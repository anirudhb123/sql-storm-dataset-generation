
WITH FilteredPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.Body, 
        p.CreationDate, 
        p.OwnerUserId, 
        p.Tags, 
        p.AnswerCount, 
        p.ViewCount, 
        p.CommentCount,
        (LENGTH(p.Tags) - LENGTH(REPLACE(p.Tags, '><', '')) + 1) AS TagCount
    FROM 
        Posts p 
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
        AND p.AnswerCount > 0
        AND p.ViewCount > 100
),

UserEngagement AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        SUM(IFNULL(c.Score, 0)) AS TotalComments, 
        SUM(IFNULL(v.BountyAmount, 0)) AS TotalBounties, 
        AVG(IFNULL(c.Score, 0)) AS AvgCommentScore,
        SUM(fp.ViewCount) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        FilteredPosts fp ON u.Id = fp.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        SUM(IFNULL(c.Score, 0)) > 0 OR SUM(IFNULL(v.BountyAmount, 0)) > 0
),

TopUsers AS (
    SELECT 
        ue.UserId, 
        ue.DisplayName, 
        ue.TotalComments, 
        ue.TotalBounties, 
        ue.AvgCommentScore, 
        ue.TotalViews,
        @rank := @rank + 1 AS UserRank
    FROM 
        UserEngagement ue, (SELECT @rank := 0) r
    ORDER BY 
        ue.TotalComments DESC, ue.TotalBounties DESC 
)

SELECT 
    tu.UserId, 
    tu.DisplayName, 
    tu.TotalComments, 
    tu.TotalBounties, 
    tu.AvgCommentScore, 
    tu.TotalViews
FROM 
    TopUsers tu
WHERE 
    tu.UserRank <= 10
ORDER BY 
    tu.TotalComments DESC, 
    tu.TotalBounties DESC;
