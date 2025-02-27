WITH TagStats AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount,
        SUM(V.VoteTypeId = 2) AS UpVotes,
        SUM(V.VoteTypeId = 3) AS DownVotes,
        ARRAY_AGG(DISTINCT U.DisplayName) AS TopUsers
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    LEFT JOIN 
        Votes V ON V.PostId = P.Id
    LEFT JOIN 
        Users U ON U.Id = P.OwnerUserId
    GROUP BY 
        T.TagName
),
TagRanked AS (
    SELECT 
        TagName,
        PostCount,
        UpVotes,
        DownVotes,
        TopUsers,
        RANK() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        TagStats
),
PopularTags AS (
    SELECT 
        TagName,
        PostCount,
        UpVotes,
        DownVotes,
        TopUsers
    FROM 
        TagRanked
    WHERE 
        Rank <= 10
),
ClosedPosts AS (
    SELECT 
        P.Title,
        P.CreationDate,
        PH.CreationDate AS CloseDate,
        PH.Comment AS CloseReason
    FROM 
        Posts P
    JOIN 
        PostHistory PH ON P.Id = PH.PostId
    WHERE 
        PH.PostHistoryTypeId = 10
)
SELECT 
    PT.TagName,
    PT.PostCount,
    PT.UpVotes,
    PT.DownVotes,
    PT.TopUsers,
    CP.Title AS ClosedPostTitle,
    CP.CreationDate AS PostCreationDate,
    CP.CloseDate,
    CP.CloseReason
FROM 
    PopularTags PT
LEFT JOIN 
    ClosedPosts CP ON PT.TagName = ANY(STRING_TO_ARRAY(CP.Title, ' '))  -- Assuming ClosedPost title includes tags
ORDER BY 
    PT.PostCount DESC, PT.UpVotes DESC;
