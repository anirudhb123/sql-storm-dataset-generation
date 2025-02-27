WITH RecursivePostHistory AS (
    -- CTE to find all revisions of posts along with related users who edited
    SELECT 
        ph.PostId, 
        ph.CreationDate, 
        ph.UserId, 
        ph.UserDisplayName, 
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS RevisionRank
    FROM 
        PostHistory ph
),
RankedPosts AS (
    -- CTE to rank posts by score and number of answers
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.AnswerCount,
        p.CreationDate,
        RANK() OVER (ORDER BY p.Score DESC, p.AnswerCount DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Considering only Questions
),
ActivitySummary AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionsAsked,
        COUNT(DISTINCT ph.Id) AS EditsMade,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        u.Id
)
SELECT 
    rp.Title,
    rp.Score,
    rp.AnswerCount,
    ph.RevisionCount,
    asum.UserId,
    asum.DisplayName,
    asum.QuestionsAsked,
    asum.EditsMade,
    asum.TotalViews,
    CASE 
        WHEN ph.UserId IS NOT NULL THEN 'Edited by ' || ph.UserDisplayName 
        ELSE 'No Edits' 
    END AS EditInfo
FROM 
    RankedPosts rp
LEFT JOIN 
    RecursivePostHistory ph ON rp.Id = ph.PostId AND ph.RevisionRank = 1 -- Latest Edit
LEFT JOIN 
    ActivitySummary asum ON rp.Id = asum.QuestionsAsked
WHERE 
    rp.PostRank <= 10 -- Top 10 Posts
ORDER BY 
    rp.Score DESC;
