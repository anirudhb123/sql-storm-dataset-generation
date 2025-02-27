WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only Questions
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalQuestions,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        AVG(p.Score) AS AverageScore,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        u.Id
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        us.DisplayName,
        us.Reputation
    FROM 
        RankedPosts rp
    JOIN 
        UserStatistics us ON rp.PostId IN (SELECT DISTINCT Id FROM Posts WHERE OwnerUserId = us.UserId)
    WHERE 
        rp.Rank <= 5 -- Top 5 questions per user
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.AnswerCount,
    tp.DisplayName,
    tp.Reputation,
    us.TotalQuestions,
    us.AcceptedAnswers,
    us.AverageScore,
    us.TotalViews
FROM 
    TopPosts tp
JOIN 
    UserStatistics us ON tp.DisplayName = us.DisplayName
ORDER BY 
    tp.ViewCount DESC, tp.Score DESC;
