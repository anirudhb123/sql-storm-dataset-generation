
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
        LEN(REPLACE(REPLACE(p.Tags, '<', ''), '>', '')) - LEN(REPLACE(p.Tags, '><', '')) + 1 AS TagCount
    FROM 
        Posts p 
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL '1 year'
        AND p.AnswerCount > 0
        AND p.ViewCount > 100
),

UserEngagement AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        SUM(ISNULL(c.Score, 0)) AS TotalComments, 
        SUM(ISNULL(v.BountyAmount, 0)) AS TotalBounties, 
        AVG(ISNULL(c.Score, 0)) AS AvgCommentScore,
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
        SUM(ISNULL(c.Score, 0)) > 0 OR SUM(ISNULL(v.BountyAmount, 0)) > 0
),

TopUsers AS (
    SELECT 
        ue.UserId, 
        ue.DisplayName, 
        ue.TotalComments, 
        ue.TotalBounties, 
        ue.AvgCommentScore, 
        ue.TotalViews,
        ROW_NUMBER() OVER (ORDER BY ue.TotalComments DESC, ue.TotalBounties DESC) AS UserRank
    FROM 
        UserEngagement ue
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
