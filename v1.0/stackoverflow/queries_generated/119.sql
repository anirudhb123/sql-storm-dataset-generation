WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(v.BountyAmount) AS TotalBounty,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 
    GROUP BY 
        u.Id
), RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.UserDisplayName,
        ph.CreationDate,
        ph.Comment,
        P.Title,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn
    FROM 
        PostHistory ph
    JOIN 
        Posts P ON ph.PostId = P.Id
    WHERE
        ph.PostHistoryTypeId IN (10, 11, 12)
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.PostCount,
    us.QuestionCount,
    us.AnswerCount,
    us.TotalBounty,
    rph.PostId,
    rph.Title AS RecentPostTitle,
    rph.UserDisplayName AS Editor,
    rph.Comment AS EditComment,
    rph.CreationDate AS EditDate
FROM 
    UserStats us
LEFT JOIN 
    RecentPostHistory rph ON us.UserId = rph.UserId
WHERE 
    us.UserRank <= 100
    AND (us.Reputation > 1000 OR us.TotalBounty > 5)
ORDER BY 
    us.Reputation DESC, 
    rph.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY;
