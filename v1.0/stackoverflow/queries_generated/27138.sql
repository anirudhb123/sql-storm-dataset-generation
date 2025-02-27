WITH TagCount AS (
    SELECT 
        Tags.TagName,
        COUNT(DISTINCT Posts.Id) AS PostCount
    FROM 
        Posts
    JOIN 
        (SELECT 
             UNNEST(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS TagName,
             Id AS PostId
         FROM 
             Posts) AS Tags
    ON 
        Posts.Id = Tags.PostId
    GROUP BY 
        Tags.TagName
),

TopUsers AS (
    SELECT 
        Users.Id AS UserId,
        Users.DisplayName,
        SUM(COALESCE(Posts.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(Posts.Score, 0)) AS TotalScore,
        COUNT(DISTINCT Posts.Id) AS PostCount
    FROM 
        Users
    LEFT JOIN 
        Posts ON Users.Id = Posts.OwnerUserId
    GROUP BY 
        Users.Id, Users.DisplayName
    ORDER BY 
        TotalScore DESC
    LIMIT 10
),

RecentEdits AS (
    SELECT 
        PostHistory.PostId,
        PostHistory.UserDisplayName,
        PostHistory.CreationDate,
        PostHistory.Comment,
        PostHistory.PostHistoryTypeId,
        ROW_NUMBER() OVER (PARTITION BY PostHistory.PostId ORDER BY PostHistory.CreationDate DESC) AS EditRank
    FROM 
        PostHistory
    WHERE 
        PostHistory.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Edit Body, Edit Tags
)

SELECT 
    tc.TagName,
    tc.PostCount,
    tu.DisplayName,
    tu.TotalViews,
    tu.TotalScore,
    re.UserDisplayName AS LastEditor,
    re.CreationDate AS LastEditDate,
    re.Comment AS EditComment
FROM 
    TagCount tc
JOIN 
    TopUsers tu ON tu.PostCount > 0
LEFT JOIN 
    RecentEdits re ON re.PostId IN (
        SELECT Id 
        FROM Posts 
        WHERE Tags LIKE '%' || tc.TagName || '%'
    )
WHERE 
    tu.UserId IN (
        SELECT OwnerUserId 
        FROM Posts 
        WHERE Tags LIKE '%' || tc.TagName || '%'
    )
ORDER BY 
    tc.PostCount DESC, tu.TotalScore DESC;
