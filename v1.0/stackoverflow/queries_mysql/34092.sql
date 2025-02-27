
WITH RecursiveTagCounts AS (
    SELECT 
        Tags.TagName, 
        COUNT(Posts.Id) AS PostCount
    FROM 
        Tags
    LEFT JOIN 
        Posts ON Posts.Tags LIKE CONCAT('%', Tags.TagName, '%')
    GROUP BY 
        Tags.TagName

    UNION ALL

    SELECT 
        Tags.TagName, 
        COUNT(Posts.Id) AS PostCount
    FROM 
        Tags
    RIGHT JOIN 
        Posts ON Posts.Tags LIKE CONCAT('%', Tags.TagName, '%')
    GROUP BY 
        Tags.TagName
), FilteredPostHistory AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate AS HistoryDate,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12)  
), ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS Author,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        MAX(ph.HistoryDate) AS LastClosedDate
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    LEFT JOIN 
        FilteredPostHistory ph ON ph.PostId = p.Id
    WHERE 
        p.Id IN (SELECT PostId FROM FilteredPostHistory WHERE PostHistoryTypeId = 10)  
    GROUP BY 
        p.Id, p.Title, u.DisplayName
)
SELECT 
    cp.PostId,
    cp.Title,
    cp.Author,
    cp.CommentCount,
    cp.VoteCount,
    cp.LastClosedDate,
    RTC.PostCount AS RelatedTagPostCount
FROM 
    ClosedPosts cp
LEFT JOIN 
    RecursiveTagCounts RTC ON RTC.TagName IN (SELECT value FROM JSON_UNQUOTE(JSON_EXTRACT(JSON_ARRAYAGG(cp.Title), '$.value')) WHERE value IS NOT NULL) 
WHERE 
    cp.LastClosedDate >= CURRENT_DATE - INTERVAL 30 DAY  
ORDER BY 
    cp.LastClosedDate DESC;
