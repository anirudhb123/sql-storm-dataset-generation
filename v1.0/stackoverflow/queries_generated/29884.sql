WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.Tags,
        U.DisplayName AS OwnerDisplayName,
        P.CreationDate,
        COALESCE(A.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        COALESCE(PH.EditBody, 'No edits made') AS MostRecentEdit,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVoteCount,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS OwnerPostRank
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Posts A ON P.AcceptedAnswerId = A.Id
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId AND PH.PostHistoryTypeId = 5  -- Edit Body
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, U.DisplayName, P.CreationDate, A.AcceptedAnswerId, PH.EditBody
),
AggregatedTags AS (
    SELECT 
        PostId,
        string_agg(tags.TagName, ', ') AS CombinedTags
    FROM 
        Posts P
    JOIN 
        unnest(string_to_array(substring(P.Tags, 2, length(P.Tags)-2), '> <')) AS TagName ON TRUE
    JOIN 
        Tags tags ON tags.TagName = TagName
    GROUP BY 
        PostId
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.OwnerDisplayName,
    RP.CreationDate,
    RP.UpVoteCount,
    RP.DownVoteCount,
    RP.AcceptedAnswerId,
    AT.CombinedTags,
    RP.MostRecentEdit
FROM 
    RankedPosts RP
LEFT JOIN 
    AggregatedTags AT ON RP.PostId = AT.PostId
WHERE 
    RP.OwnerPostRank <= 5  -- Get only the 5 most recent posts from each user
ORDER BY 
    RP.CreationDate DESC;

This query benchmarks string processing by aggregating tags from posts, along with incorporating user displays, vote counts, and acceptance of answers, while applying ranking to analyze recent activity per user.
