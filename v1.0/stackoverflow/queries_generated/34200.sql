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
        p.PostTypeId = 1 -- Only questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year' -- Posts created in the last year
),
PopularTags AS (
    SELECT
        unnest(string_to_array(Tags, ',')) AS TagName,
        COUNT(*) AS TagCount
    FROM
        Posts
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
        ph.PostHistoryTypeId IN (4, 5, 6) -- Title, Body, or Tag updates
        AND ph.CreationDate >= NOW() - INTERVAL '6 months'
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
        re.ChangeComment
    FROM
        RankedPosts rp
    LEFT JOIN PopularTags pt ON pt.TagName = ANY(string_to_array(rp.Title, ' ')) -- Join based on title containing popular tags
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
    COALESCE(fr.EditDate::text, 'Never Edited') AS LastEditDate,
    COALESCE(fr.ChangeComment, 'No Changes') AS LastChangeComment
FROM
    FinalResults fr
WHERE
    fr.Rank <= 5 -- Top 5 posts
ORDER BY
    fr.Score DESC, fr.ViewCount DESC;
