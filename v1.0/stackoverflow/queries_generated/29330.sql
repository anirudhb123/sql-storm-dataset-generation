WITH UserPosts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName AS UserName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    WHERE u.Reputation >= 1000
    GROUP BY u.Id, u.DisplayName
),
PostTags AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(TRIM(BOTH '<>' FROM unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><'))), ', ') AS TagsList
    FROM Posts p
    WHERE p.PostTypeId = 1
    GROUP BY p.Id
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        up.UserName AS OwnerName,
        pt.TagsList
    FROM Posts p
    JOIN UserPosts up ON p.OwnerUserId = up.UserId
    LEFT JOIN PostTags pt ON p.Id = pt.PostId
    WHERE p.ViewCount > 100 AND p.Score >= 5
),
RankedPosts AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.CreationDate,
        pd.ViewCount,
        pd.OwnerName,
        pd.TagsList,
        ROW_NUMBER() OVER (ORDER BY pd.ViewCount DESC, pd.CreationDate DESC) AS PostRank
    FROM PostDetails pd
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.OwnerName,
    rp.TagsList
FROM RankedPosts rp
WHERE rp.PostRank <= 10
ORDER BY rp.ViewCount DESC;
