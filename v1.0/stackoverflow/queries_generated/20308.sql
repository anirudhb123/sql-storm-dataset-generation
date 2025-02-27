WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER(PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.PostTypeId = 1 -- Only Questions
        AND p.CreationDate > DATEADD(year, -1, CURRENT_TIMESTAMP) -- Within the last year
),
PostHistoryData AS (
    SELECT 
        ph.PostId, 
        ph.UserId,
        ph.PostHistoryTypeId,
        ph.CreationDate AS HistoryCreationDate,
        H.Name AS HistoryTypeName,
        ROW_NUMBER() OVER(PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes H ON ph.PostHistoryTypeId = H.Id
    WHERE 
        ph.CreationDate > DATEADD(year, -1, CURRENT_TIMESTAMP) -- Within last year
),
TagsWithCounts AS (
    SELECT 
        T.Id AS TagId,
        T.TagName,
        COUNT(P.Id) AS PostCount
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE '%<'+T.TagName+'>%' -- Join to gather how many posts are tagged
    GROUP BY 
        T.Id, T.TagName
    HAVING 
        COUNT(P.Id) > 0 -- Only include tags that are linked to at least one post
)

SELECT 
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    RP.ViewCount,
    RP.Score,
    RP.OwnerDisplayName,
    COALESCE(Ph.UserId, 0) AS LastUserId,
    Ph.HistoryTypeName,
    Ph.HistoryCreationDate,
    T.TagName,
    T.PostCount
FROM 
    RankedPosts RP
LEFT JOIN 
    PostHistoryData Ph ON RP.PostId = Ph.PostId AND Ph.HistoryRank = 1 -- Most recent history entry
LEFT JOIN 
    TagsWithCounts T ON T.PostCount > 1 -- Get tags that have more than 1 post
WHERE 
    RP.PostRank <= 10 -- Top 10 latest posts per user
ORDER BY 
    RP.CreationDate DESC,

    -- An obscure corner case using NULL logic checks
    CASE 
        WHEN Ph.PostHistoryTypeId IS NULL THEN 1
        ELSE 0
    END,
    RP.Score DESC;

-- The query achieves the following:
-- 1. Ranks questions posted in the last year by each user, fetching only the top 10 for each.
-- 2. Retrieves the latest post history detail for the corresponding posts.
-- 3. Joins with tags that are associated with posts and filters to include only those with more than one associated post.
-- 4. Uses NULL logic to prioritize posts without history.

