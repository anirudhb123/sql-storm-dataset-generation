
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerName,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM
        Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE
        p.PostTypeId = 1 
        AND p.CreationDate >= NOW() - INTERVAL 1 YEAR 
),
PopularTags AS (
    SELECT
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, ',', numbers.n), ',', -1) AS TagName,
        COUNT(*) AS TagCount
    FROM
        Posts
    JOIN (
        SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
        UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10
    ) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, ',', '')) >= numbers.n - 1
    WHERE
        PostTypeId = 1
    GROUP BY
        TagName
    HAVING
        COUNT(*) > 5
),
RecentEdits AS (
    SELECT
        p.Id AS PostId,
        ph.UserId,
        ph.UserDisplayName,
        ph.CreationDate AS EditDate,
        ph.Comment AS ChangeComment
    FROM
        PostHistory ph
    JOIN Posts p ON ph.PostId = p.Id
    WHERE
        ph.PostHistoryTypeId IN (4, 5, 6) 
        AND ph.CreationDate >= NOW() - INTERVAL 6 MONTH
),
FinalResults AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.OwnerName,
        rp.Score,
        rp.ViewCount,
        pt.TagName,
        re.UserDisplayName AS EditorName,
        re.EditDate,
        re.ChangeComment,
        rp.Rank
    FROM
        RankedPosts rp
    LEFT JOIN PopularTags pt ON FIND_IN_SET(pt.TagName, rp.Title) 
    LEFT JOIN RecentEdits re ON re.PostId = rp.PostId
)
SELECT
    fr.PostId,
    fr.Title,
    fr.OwnerName,
    fr.Score,
    fr.ViewCount,
    COALESCE(fr.TagName, 'No Tags') AS PopularTag,
    COALESCE(fr.EditorName, 'No Edits') AS LastEditor,
    COALESCE(CAST(fr.EditDate AS CHAR), 'Never Edited') AS LastEditDate,
    COALESCE(fr.ChangeComment, 'No Changes') AS LastChangeComment
FROM
    FinalResults fr
WHERE
    fr.Rank <= 5 
ORDER BY
    fr.Score DESC, fr.ViewCount DESC;
