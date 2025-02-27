
WITH FilteredPosts AS (
    SELECT
        p.Id AS PostID,
        p.Title,
        p.ViewCount,
        p.Tags,
        GROUP_CONCAT(t.TagName SEPARATOR ', ') AS TagList,
        U.DisplayName AS OwnerDisplayName
    FROM
        Posts p
    JOIN
        Users U ON p.OwnerUserId = U.Id
    LEFT JOIN 
        Tags t ON t.WikiPostId = p.Id OR t.ExcerptPostId = p.Id
    WHERE
        p.CreationDate >= DATE_SUB(CAST('2024-10-01' AS DATE), INTERVAL 1 MONTH)
        AND p.PostTypeId IN (1, 2)  
    GROUP BY
        p.Id, p.Title, p.ViewCount, p.Tags, U.DisplayName
),
PostScore AS (
    SELECT
        PostID,
        Title,
        ViewCount,
        TagList,
        OwnerDisplayName,
        @rank := IF(@prev_view_count = ViewCount, @rank, @rank + 1) AS ViewRank,
        @prev_view_count := ViewCount
    FROM
        FilteredPosts, (SELECT @rank := 0, @prev_view_count := NULL) r
    ORDER BY ViewCount DESC
),
ClosedPostHistory AS (
    SELECT
        ph.PostId,
        ph.CreationDate,
        ph.UserDisplayName AS ClosedBy,
        c.Name AS CloseReason
    FROM
        PostHistory ph
    JOIN
        CloseReasonTypes c ON CAST(ph.Comment AS UNSIGNED) = c.Id
    WHERE
        ph.PostHistoryTypeId = 10  
)
SELECT 
    ps.PostID, 
    ps.Title, 
    ps.ViewCount, 
    ps.TagList, 
    ps.OwnerDisplayName, 
    ps.ViewRank,
    COALESCE(cph.ClosedBy, 'Not Closed') AS ClosedBy,
    COALESCE(cph.CloseReason, 'N/A') AS CloseReason
FROM 
    PostScore ps
LEFT JOIN 
    ClosedPostHistory cph ON ps.PostID = cph.PostId
ORDER BY 
    ps.ViewRank;
