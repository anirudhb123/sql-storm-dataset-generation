WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        DATE_TRUNC('month', u.CreationDate) AS AccountCreationMonth
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, DATE_TRUNC('month', u.CreationDate)
), MonthlyActivity AS (
    SELECT 
        AccountCreationMonth,
        SUM(PostCount) AS TotalPosts,
        SUM(CommentCount) AS TotalComments,
        SUM(VoteCount) AS TotalVotes,
        SUM(GoldBadges) AS TotalGoldBadges,
        SUM(SilverBadges) AS TotalSilverBadges,
        SUM(BronzeBadges) AS TotalBronzeBadges
    FROM 
        UserActivity
    GROUP BY 
        AccountCreationMonth
)
SELECT 
    AccountCreationMonth,
    TotalPosts,
    TotalComments,
    TotalVotes,
    TotalGoldBadges,
    TotalSilverBadges,
    TotalBronzeBadges,
    RANK() OVER (ORDER BY TotalPosts DESC) AS RankByPosts,
    RANK() OVER (ORDER BY TotalComments DESC) AS RankByComments,
    RANK() OVER (ORDER BY TotalVotes DESC) AS RankByVotes
FROM 
    MonthlyActivity
ORDER BY 
    AccountCreationMonth;
