WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        U.DisplayName AS OwnerDisplayName,
        P.CreationDate,
        P.Score,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC, P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.PostTypeId IN (1, 2) -- Considering only Questions and Answers
    GROUP BY 
        P.Id, P.Title, U.DisplayName, P.CreationDate, P.Score
),
TopRankedPosts AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.OwnerDisplayName,
        RP.CreationDate,
        RP.Score,
        RP.UpVotes,
        RP.DownVotes
    FROM 
        RankedPosts RP
    WHERE 
        PostRank <= 10
),
PostStats AS (
    SELECT 
        T.Tags,
        COUNT(DISTINCT T.Id) AS TagCount,
        SUM(P.ViewCount) AS TotalViews
    FROM 
        Posts P
    JOIN 
        (SELECT 
            Id, 
            STRING_AGG(T.TagName, ', ') AS Tags 
         FROM 
            (SELECT 
                PostId, 
                Tags 
             FROM 
                Posts 
             WHERE 
                PostTypeId = 1) AS PostTags
         JOIN 
            Tags T ON PostTags.Tags LIKE '%' + T.TagName + '%'
         GROUP BY 
            PostId) T ON P.Id = T.Id
    GROUP BY 
        T.Tags
)
SELECT 
    TRP.Title,
    TRP.OwnerDisplayName,
    TRP.CreationDate,
    TRP.Score,
    TRP.UpVotes,
    TRP.DownVotes,
    PS.TagCount,
    PS.TotalViews
FROM 
    TopRankedPosts TRP
JOIN 
    PostStats PS ON TRP.PostId = PS.PostId
ORDER BY 
    TRP.Score DESC, TRP.CreationDate DESC;
