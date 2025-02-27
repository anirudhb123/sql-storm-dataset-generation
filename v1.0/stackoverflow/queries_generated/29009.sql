WITH Ranked Posts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.LastActivityDate,
        p.AnswerCount,
        p.ViewCount,
        p.Body,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) as Ranking
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Only questions
        AND p.ViewCount > 1000  -- Focus on popular questions
),
RecentPostHistory AS (
    SELECT 
        ph.PostId, 
        ph.PostHistoryTypeId, 
        ph.CreationDate,
        pt.Name AS PostHistoryTypeName,
        ph.UserDisplayName,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) as PhRanking
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    WHERE 
        ph.CreationDate >= CURRENT_DATE - INTERVAL '30 DAY'  -- Last 30 days
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.AnswerCount, 0)) AS TotalAnswers,
        COUNT(DISTINCT p.Id) AS QuestionCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1  -- Join with questions
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(DISTINCT p.Id) > 5  -- Users with more than 5 questions
),
PopularQuestions AS (
    SELECT 
        r.Id, 
        r.Title, 
        r.CreationDate,
        r.LastActivityDate,
        r.AnswerCount,
        r.ViewCount,
        string_agg(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        RankedPosts r
    JOIN 
        Posts p ON r.Id = p.Id
    LEFT JOIN 
        Tags t ON t.ExcerptPostId = p.Id  -- Presuming tags are linked this way
    GROUP BY 
        r.Id, r.Title, r.CreationDate, r.LastActivityDate, r.AnswerCount, r.ViewCount
    ORDER BY 
        r.ViewCount DESC
    LIMIT 10
)
SELECT 
    pq.Title,
    pq.CreationDate,
    pq.LastActivityDate,
    pq.AnswerCount,
    pq.ViewCount,
    pu.DisplayName AS TopUser,
    pp.PostHistoryTypeName,
    pp.CreationDate AS HistoryDate,
    pp.Comment AS UserComment
FROM 
    PopularQuestions pq
JOIN 
    RecentPostHistory pp ON pq.Id = pp.PostId
JOIN 
    TopUsers pu ON pq.OwnerUserId = pu.UserId
WHERE 
    pp.PhRanking = 1  -- Get most recent history entry
ORDER BY 
    pq.ViewCount DESC, 
    pp.CreationDate DESC;
