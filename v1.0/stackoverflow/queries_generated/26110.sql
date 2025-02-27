WITH RankedPosts AS (
    SELECT
        p.Id AS PostID,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserPostRank
    FROM Posts p
    WHERE p.PostTypeId = 1 -- Only Questions
),
TopUsers AS (
    SELECT 
        u.Id AS UserID,
        u.DisplayName,
        COUNT(p.Id) AS QuestionCount,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(COALESCE(b.Class, 0)) AS TotalBadges
    FROM Users u
    JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 9 -- BountyClose
    LEFT JOIN Badges b ON u.Id = b.UserId
    WHERE p.PostTypeId = 1 -- Only Questions
    GROUP BY u.Id, u.DisplayName
    ORDER BY TotalScore DESC
    LIMIT 10
),
UserDetails AS (
    SELECT 
        u.Id AS UserID,
        u.DisplayName,
        u.Reputation,
        b.Count AS BadgeCount,
        COALESCE(SUM(ph.PostId IS NOT NULL), 0) AS EditCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN PostHistory ph ON u.Id = ph.UserId
    GROUP BY u.Id, u.DisplayName, u.Reputation, b.Count
),
TopQuestionDetails AS (
    SELECT 
        rp.PostID,
        rp.Title, 
        rp.ViewCount,
        rp.Score,
        rp.CreationDate,
        u.DisplayName AS OwnerDisplayName
    FROM RankedPosts rp
    JOIN Users u ON rp.OwnerUserId = u.Id
    WHERE UserPostRank <= 5 -- Top 5 Posts per User
)
SELECT 
    tu.UserID,
    tu.DisplayName AS TopUserDisplayName,
    tu.QuestionCount,
    tu.TotalBounties,
    tu.TotalScore,
    ud.BadgeCount,
    ud.EditCount,
    COUNT(tqd.PostID) AS TopQuestions,
    STRING_AGG(tqd.Title, '; ') AS TopQuestionTitles
FROM TopUsers tu
JOIN UserDetails ud ON tu.UserID = ud.UserID
LEFT JOIN TopQuestionDetails tqd ON tu.UserID = tqd.OwnerUserId
GROUP BY tu.UserID, tu.DisplayName, tu.QuestionCount, tu.TotalBounties, tu.TotalScore, ud.BadgeCount, ud.EditCount
ORDER BY tu.TotalScore DESC;
