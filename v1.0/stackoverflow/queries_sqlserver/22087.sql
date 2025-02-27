
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS RankByViews
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS datetime) - DATEADD(MONTH, 6, 0)
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.PostTypeId
),
AcceptedAnswers AS (
    SELECT 
        p.Id AS AnswerId,
        pa.Id AS QuestionId,
        pa.Title AS QuestionTitle,
        pa.OwnerUserId AS QuestionOwnerId,
        p.OwnerUserId AS AnswerOwnerId,
        p.CreationDate AS AnswerCreationDate,
        RANK() OVER (PARTITION BY pa.Id ORDER BY p.CreationDate) AS AnswerRank
    FROM 
        Posts p
    JOIN 
        Posts pa ON p.ParentId = pa.Id
    WHERE 
        pa.PostTypeId = 1 AND p.AcceptedAnswerId IS NOT NULL
),
TopCommenters AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(c.Id) AS TotalComments
    FROM 
        Users u
    JOIN 
        Comments c ON u.Id = c.UserId
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(c.Id) > 10
),
PostHistorySummary AS (
    SELECT 
        postId,
        STRING_AGG(DISTINCT pht.Name + ': ' + CAST(ph.CreationDate AS nvarchar(max)), '; ') AS HistoryDetails
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        postId
),
FinalResults AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.CommentCount,
        COALESCE(aa.QuestionOwnerId, -1) AS RelatedQuestionOwnerId,
        COALESCE(aa.QuestionTitle, 'No Accepted Answer') AS RelatedQuestionTitle,
        phs.HistoryDetails,
        CASE 
            WHEN tcm.TotalComments IS NOT NULL THEN 'Top Commenter: ' + tcm.DisplayName + ' (' + CAST(tcm.TotalComments AS nvarchar(max)) + ' comments)'
            ELSE 'No Top Commenter'
        END AS TopCommenter
    FROM 
        RankedPosts rp
    LEFT JOIN 
        AcceptedAnswers aa ON rp.PostId = aa.AnswerId
    LEFT JOIN 
        PostHistorySummary phs ON rp.PostId = phs.postId
    LEFT JOIN 
        TopCommenters tcm ON rp.CommentCount <= tcm.TotalComments
    WHERE 
        rp.RankByViews <= 5
)

SELECT 
    PostId,
    Title,
    ViewCount,
    CommentCount,
    RelatedQuestionOwnerId,
    RelatedQuestionTitle,
    HistoryDetails,
    TopCommenter
FROM 
    FinalResults
ORDER BY 
    ViewCount DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
