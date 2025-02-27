WITH RecursiveTagCounts AS (
    SELECT
        Tags.Id AS TagId,
        Tags.TagName,
        COUNT(*) AS PostCount
    FROM 
        Tags 
    LEFT JOIN 
        Posts ON Tags.Id = ANY(string_to_array(Posts.Tags, '::int'))
    GROUP BY 
        Tags.Id
),
RecentPosts AS (
    SELECT 
        P.Id,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        COUNT(A.Id) AS AnswerCount
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Posts A ON A.ParentId = P.Id AND A.PostTypeId = 2
    WHERE 
        P.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY 
        P.Id, U.DisplayName
),
PostHistories AS (
    SELECT 
        PH.PostId,
        COUNT(*) AS EditCount,
        MAX(PH.CreationDate) AS LastEditDate
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (4, 5) -- Edit Title, Edit Body
    GROUP BY 
        PH.PostId
),
TopUserScores AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation + COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE -1 END), 0) AS TotalScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id
)
SELECT 
    T.TagName,
    COUNT(DISTINCT RP.Id) AS RecentPostCount,
    SUM(PH.EditCount) AS TotalEdits,
    TPC.TotalScore,
    MAX(RP.ViewCount) AS MaxViewCount,
    AVG(RP.ViewCount) AS AverageViewCount
FROM 
    RecursiveTagCounts T
LEFT JOIN 
    Posts P ON T.PostCount = (SELECT COUNT(*) FROM Posts WHERE Tags LIKE '%' || T.TagName || '%')
LEFT JOIN 
    RecentPosts RP ON P.Id = RP.Id
LEFT JOIN 
    PostHistories PH ON P.Id = PH.PostId
LEFT JOIN 
    TopUserScores TPC ON RP.OwnerDisplayName = TPC.DisplayName
WHERE 
    T.PostCount > 10 
GROUP BY 
    T.TagName, TPC.TotalScore
ORDER BY 
    RecentPostCount DESC, TotalEdits DESC;
