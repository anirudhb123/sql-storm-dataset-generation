WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= DATEADD(year, -1, GETDATE()) 
        AND p.Score >= 0
),
TopQuestions AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount, 
        rp.Score,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.PostId = u.Id 
    WHERE 
        rp.rn <= 10  -- Top 10 questions per PostTypeId
),
PostDetails AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS QuestionCount,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' + t.TagName + '%'
    WHERE 
        p.PostTypeId = 1 -- Questions only
    GROUP BY 
        t.TagName
),
RecentActivity AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS HistoryDate,
        ph.UserDisplayName,
        ph.PostHistoryTypeId,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS history_rn
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= DATEADD(month, -6, GETDATE()) 
        AND ph.PostHistoryTypeId IN (10, 11, 12) -- Close, Reopen, Delete
),
FinalResult AS (
    SELECT 
        tq.PostId,
        tq.Title,
        tq.CreationDate,
        tq.ViewCount,
        tq.Score,
        tq.OwnerDisplayName,
        tq.OwnerReputation,
        pd.TagName,
        pd.QuestionCount,
        pd.TotalScore,
        pd.TotalViews,
        ra.UserDisplayName AS LastUser,
        ra.HistoryDate,
        ra.Comment AS LastComment
    FROM 
        TopQuestions tq
    LEFT JOIN 
        PostDetails pd ON pd.QuestionCount > 0
    LEFT JOIN 
        RecentActivity ra ON tq.PostId = ra.PostId AND ra.history_rn = 1
)

SELECT 
    PostId,
    Title,
    CreationDate,
    ViewCount,
    Score,
    OwnerDisplayName,
    OwnerReputation,
    TagName,
    QuestionCount,
    TotalScore,
    TotalViews,
    COALESCE(LastUser, 'No Activity') AS LastUser,
    COALESCE(HistoryDate, 'No Activity') AS LastActivityDate,
    COALESCE(LastComment, 'No Activity') AS LastComment
FROM 
    FinalResult
ORDER BY 
    Score DESC, CreationDate DESC
OPTION (MAXRECURSION 100);
