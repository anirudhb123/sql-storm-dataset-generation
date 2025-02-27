WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        U.DisplayName AS OwnerName,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        (SELECT STRING_AGG(Tag.TagName, ', ') 
         FROM Tags AS Tag 
         WHERE Tag.Id IN (SELECT UNNEST(string_to_array(P.Tags, '><')::int[]))) AS TagList,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS Rank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON V.PostId = P.Id
    WHERE 
        P.PostTypeId = 1 -- Only questions
    GROUP BY 
        P.Id, P.Title, P.Body, P.CreationDate, P.ViewCount, P.Score, U.DisplayName
),
RecentPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        CreationDate,
        ViewCount,
        Score,
        OwnerName,
        UpVotes,
        DownVotes,
        TagList
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.Body,
    RP.CreationDate,
    RP.ViewCount,
    RP.Score,
    RP.OwnerName,
    RP.UpVotes,
    RP.DownVotes,
    RP.TagList,
    (SELECT COUNT(*) FROM Comments C WHERE C.PostId = RP.PostId) AS CommentCount,
    (SELECT COUNT(*) FROM PostHistory PH WHERE PH.PostId = RP.PostId AND PH.PostHistoryTypeId IN (10, 11)) AS CloseReopenCount
FROM 
    RecentPosts RP
ORDER BY 
    RP.Score DESC, 
    RP.ViewCount DESC;
