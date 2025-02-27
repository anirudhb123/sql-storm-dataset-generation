WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COALESCE(u.Reputation, 0) AS UserReputation,
        ARRAY_AGG(DISTINCT t.TagName) AS TagsArray
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        LATERAL (SELECT * FROM string_to_array(p.Tags, '>')) AS tags ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = tags.array
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
        AND p.PostTypeId IN (1, 2)  -- Only questions and answers
    GROUP BY 
        p.Id, u.Reputation
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.Comment,
        ph.CreationDate,
        p.Title AS PostTitle,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS Closed,
        MAX(CASE WHEN ph.PostHistoryTypeId IN (11, 13) THEN 1 ELSE 0 END) AS Opened,
        COUNT(*) FILTER (WHERE ph.PostHistoryTypeId IN (2, 4, 6)) AS EditCount
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    GROUP BY 
        ph.PostId, p.Title
)
SELECT 
    r.PostId,
    r.Title,
    r.CreationDate,
    r.Score,
    r.ViewCount,
    r.UserReputation,
    r.TagsArray,
    COALESCE(phd.Closed, 0) AS IsClosed,
    COALESCE(phd.Opened, 0) AS IsOpened,
    phd.EditCount
FROM 
    RankedPosts r
LEFT JOIN 
    PostHistoryDetails phd ON r.PostId = phd.PostId
WHERE 
    r.rn = 1  -- Only the latest post per user
    AND (r.Score > 0 OR r.ViewCount > 100)  -- Filter condition
ORDER BY 
    r.UserReputation DESC,
    r.Score DESC,
    r.CreationDate ASC
LIMIT 100;

-- Count the distinct tag references for closed questions, with additional details
WITH ClosedQuestionTags AS (
    SELECT 
        STRING_AGG(DISTINCT t.TagName, ', ' ORDER BY t.TagName) AS TagNames,
        COUNT(DISTINCT p.Id) AS ClosedQuestionCount
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    JOIN 
        Tags t ON t.TagName = ANY(STRING_TO_ARRAY(p.Tags, '>'))
    WHERE 
        ph.PostHistoryTypeId = 10  -- Closed
    GROUP BY 
        t.TagName
)
SELECT 
    *,
    CASE 
        WHEN ClosedQuestionCount > 100 THEN 'Popular Tag'
        WHEN ClosedQuestionCount BETWEEN 50 AND 100 THEN 'Moderately Closed'
        ELSE 'Rarely Closed'
    END AS ClosurePopularity
FROM 
    ClosedQuestionTags
WHERE 
    CLOSEDQUESTIONCOUNT IS NOT NULL
ORDER BY 
    ClosedQuestionCount DESC
LIMIT 50;

-- Distinct count of users who edited posts, considering different types of edits
SELECT 
    u.DisplayName,
    COUNT(DISTINCT ph.PostId) AS UniqueEditedPosts,
    SUM(CASE WHEN ph.PostHistoryTypeId IN (4, 6) THEN 1 ELSE 0 END) AS TitleOrTagsEdited,
    COUNT(CASE WHEN ph.PostHistoryTypeId = 24 THEN 1 ELSE NULL END) AS SuggestedEditsMade
FROM 
    PostHistory ph
JOIN 
    Users u ON ph.UserId = u.Id
GROUP BY 
    u.DisplayName
HAVING 
    COUNT(DISTINCT ph.PostId) > 5  -- More than 5 edits made
ORDER BY 
    UniqueEditedPosts DESC
LIMIT 20;
