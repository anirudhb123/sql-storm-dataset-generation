WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- We are interested only in Questions
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(p.Id) AS QuestionCount,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        u.Id
    HAVING 
        COUNT(p.Id) > 5 -- Users with more than 5 questions
),
PostWithHistory AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate AS HistoryCreationDate,
        COUNT(*) AS HistoryCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
    HAVING 
        ph.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Edit Body, Edit Tags
),
FinalOutput AS (
    SELECT 
        tu.DisplayName,
        tu.Reputation,
        tu.QuestionCount,
        tu.TotalScore,
        tu.TotalViews,
        pp.PostId,
        pp.Title,
        pp.CreationDate,
        ph.HistoryCount,
        pp.Rank
    FROM 
        TopUsers tu
    JOIN 
        RankedPosts pp ON tu.UserId = pp.OwnerUserId
    LEFT JOIN 
        PostWithHistory ph ON pp.PostId = ph.PostId
    WHERE 
        pp.Rank <= 3 -- Top 3 Posts per User
)
SELECT 
    DisplayName,
    Reputation,
    QuestionCount,
    TotalScore,
    TotalViews,
    PostId,
    Title,
    CreationDate,
    HistoryCount
FROM 
    FinalOutput
ORDER BY 
    Reputation DESC, TotalScore DESC;
