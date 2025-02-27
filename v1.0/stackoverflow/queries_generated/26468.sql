WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.LastActivityDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        COALESCE(h.Comment, '') AS LastActionComment,
        COALESCE(ph.PostHistoryTypeId, 0) AS LastHistoryType,
        CASE 
            WHEN h.CreationDate IS NOT NULL THEN 
                'Last action on post was a ' || (
                    SELECT Name 
                    FROM PostHistoryTypes 
                    WHERE Id = COALESCE(ph.PostHistoryTypeId, 0)
                )
            ELSE 
                'No recent actions'
        END AS LastActionDescription
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            MAX(CreationDate) AS MaxCreationDate
        FROM 
            PostHistory
        GROUP BY 
            PostId
    ) max_ph ON max_ph.PostId = ph.PostId
    LEFT JOIN 
        PostHistory h ON max_ph.PostId = h.PostId AND max_ph.MaxCreationDate = h.CreationDate
    WHERE 
        p.PostTypeId = 1 -- Filtering only Questions
),
TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore
    FROM 
        Tags t 
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.OwnerDisplayName,
    pd.LastActivityDate,
    pd.ViewCount,
    pd.Score,
    pd.AnswerCount,
    pd.CommentCount,
    pd.FavoriteCount,
    pd.LastActionDescription,
    ts.TagName,
    ts.PostCount,
    ts.TotalViews,
    ts.TotalScore
FROM 
    PostDetails pd
LEFT JOIN 
    TagStatistics ts ON pd.Tags LIKE '%' || ts.TagName || '%'
ORDER BY 
    pd.LastActivityDate DESC, 
    ts.TotalScore DESC
LIMIT 100;
